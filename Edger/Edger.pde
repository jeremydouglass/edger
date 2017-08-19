/** edger -- an edge list converter
 * Jeremy Douglass
 * Processing 3.3.5
 * 2017-08-17
 **/

import java.io.ByteArrayInputStream;

File workingDir; 
String os;
String actionText;
boolean GRAPHVIZ_INSTALLED = false;
int runState;

void setup() { 
  println("EDGER");
  os = System.getProperty("os.name");
  println("OS: ", os);
  workingDir = new File(sketchPath("")); // or dataPath
  selectFolder("Select a folder of .txt files:", "selectFolder");
  actionText = "select\n   folder...";
  textAlign(CENTER, CENTER);
  noStroke();
}

void draw() {
  background(0);

  fill(0);
  rect(0, 0, width, height/4);
  fill(255);
  textSize(18);
  text("EDGER", width/2, height/8);

  switch(runState) {
  case 0:
    fill(0, 0, 255);
    actionText = "refresh\ngraphs";
    break;
  case 1:
    fill(255, 0, 0);
    actionText = "   running...";
    runState = 2;
    break;
  case 2:
    batch(workingDir, ".txt");
    runState = 0;
    delay(500);
    break;
  }
  rect(0, height/4, width, 3*height/4);
  fill(255);
  textSize(14);
  text(actionText, width/2, 7*height/12);
  if (GRAPHVIZ_INSTALLED) {
    textSize(10);
    text("+PNG", width/2, height-10);
  }
}

void mouseClicked() {
  runState = 1;
}
void keyPressed() {
  if (key=='p'||key=='P') {
    GRAPHVIZ_INSTALLED = !GRAPHVIZ_INSTALLED;
  }
}


void selectFolder(File selection) {
  if (selection == null) {
    println("No selection (canceled or closed)");
    exit();
  } else {
    println("Selected:\n    " + selection.getAbsolutePath() + "\n");
    workingDir = selection;
    runState = 1;
  }
}

void batch(File workingDir, String ext) {
  File [] files = workingDir.listFiles();

  // loop through file list 
  for (int i = 0; i < files.length; i++) {
    String fname = files[i].getName();
    if (fname.toLowerCase().endsWith(ext)) {
      Table fileTable = tableLoader(files[i].getAbsolutePath());
      // GV
      String outGraphviz = files[i].getParent() + "/gv/" + fname + ".gv";
      makeGraphviz(outGraphviz, fileTable);
      // TGF
      String outTGF = files[i].getParent() + "/tgf/" + fname + ".tgf";
      makeTGF(outTGF, fileTable);
      // PNG
      if (os.equals("Mac OS X") && GRAPHVIZ_INSTALLED) {
        String[] params = { "/usr/local/bin/dot", "-Tpng", "-O", outGraphviz }; // e.g. dot -Tpng -O  *.gv
        exec(params);
      }
      if (os.toLowerCase().startsWith("win") && GRAPHVIZ_INSTALLED) {
        String[] params = { "C:/Program Files (x86)/Graphviz/bin/dot.exe", "-Tpng", "-O", outGraphviz };
        exec(params);
      }
    }
  }
}

void makeTGF(String outDir, String file) {
  Table table = tableLoader(file);
  makeTGF(outDir, table);
}
void makeTGF(String outDir, Table table) {
  StringList tgf = new StringList();
  StringList tgfnodes = new StringList();
  StringList tgfedges = new StringList();

  String headnode = "";

  for (TableRow row : table.rows()) {

    // fill in duplicate origins:
    // if origin / node not specified
    if (row.getString(0)==null || row.getString(0).equals("")) {
      // load cached origin
      if (!headnode.equals("")) {
        row.setString(0, headnode);
      }
    } else {
      // cache origin
      headnode=row.getString(0);
    }

    if (row.getString(1)==null || row.getString(1).equals("")) {
      String node = "" + row.getInt(0);
      if (row.getString(2)!=null) {
        node = node + "\t" + row.getString(2);
      }
      tgfnodes.append(node);
    } else {
      String edge = "" + row.getInt(0) + "\t" + row.getInt(1);
      if (row.getString(2)!=null) {
        edge = edge + "\t" + row.getString(2);
      }
      tgfedges.append(edge);
    }
  }
  for (int i=0; i<tgfnodes.size(); i++) {
    tgf.append(tgfnodes.get(i));
  }
  tgf.append("#");
  for (int i=0; i<tgfedges.size(); i++) {
    tgf.append(tgfedges.get(i));
  }
  // for(String s: tgf.array()){ println(s); }
  saveStrings(outDir, tgf.array());
}


void makeGraphviz(String outDir, String file) {
  Table table = tableLoader(file);
  makeGraphviz(outDir, table);
}
void makeGraphviz(String outDir, Table table) {
  StringList graphviz = new StringList(); // GV graphviz dot file lines
  graphviz.append("digraph g{");
  graphviz.append("  graph [rankdir=LR];");
  graphviz.append("  node  [shape=square];");

  String headnode = "";

  for (TableRow row : table.rows()) {

    // fill in duplicate origins if origin / node not specified
    if (row.getString(0)==null || row.getString(0).equals("")) {
      // load cached origin
      if (!headnode.equals("")) {
        row.setString(0, headnode);
      }
    } else {
      // cache origin
      headnode=row.getString(0);
    }

    String edge = "  " + row.getInt(0);
    if (row.getString(1)==null || row.getString(1).equals("")) {
      edge = edge + "      ";
    } else {
      edge = edge + " -> " + row.getInt(1);
    }
    if (row.getString(2)!=null) {
      edge = edge + "\t" + "[label=" + "\"" + row.getString(2).replace("\"", "") + "\"" + "]";
    }
    edge = edge + ";";

    if (table.getColumnCount()>3) {
      String comment = "";
      // accumulate comment columns into one string
      for (int i=3; i<table.getColumnCount(); i++) {
        if (row.getString(i)!=null && !row.getString(i).equals("")) {
          comment = comment + row.getString(i) + "\t";
        }
      }
      // add comment if not empty
      if (!comment.equals("")) {
        edge = edge + "\t# " + comment.trim();
      }
    }
    graphviz.append(edge);
  }
  graphviz.append("}\n");
  // for (String s : graphviz) { println(s); }
  saveStrings(outDir, graphviz.array());
}

/**
 * Takes a TSV tab-separated file string (no header)
 * that describes a sparse edge list with comments
 * pre-processes it for graph parsing (empty rows, padding)
 * and returns the filestring as a Table.
 */
Table tableLoader(String fileName) {

  // clean file line strings
  StringList flist = new StringList(loadStrings(fileName));
  for (int i=flist.size() - 1; i >= 0; i--) {
    String s = trim(flist.get(i));
    // delete empty lines
    if (s.equals(null) || s.isEmpty()) {
      // println("empty: ", s);
      flist.remove(i);
      continue;
    } else {
      // strip non-empty comment-only lines beginning with #
      if (s.charAt(0)=='#') {
        // flist.set(i, s);
        flist.remove(i);
        continue;
      }
    }
  }
  String fileString = join(flist.array(), "\n");

  // parse TSV filestring into Table object
  Table table = new Table();
  try {
    InputStream stream = new ByteArrayInputStream(fileString.getBytes("UTF-8"));
    table = new Table(stream, "tsv");
  }
  catch(IOException ie) {
    ie.printStackTrace();
  }

  // add full columns
  if (table.getColumnCount()<1) {
    table.addColumn("source");
  }
  if (table.getColumnCount()<2) {
    table.addColumn("destination");
  }
  if (table.getColumnCount()<3) {
    table.addColumn("label");
  }
  if (table.getColumnCount()<4) {
    table.addColumn("comment");
  }
  return(table);
}