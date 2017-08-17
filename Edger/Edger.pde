/** edger -- an edge list converter
 * Jeremy Douglass
 * Processing 3.3.5
 * 2017-08-16
 **/

File dir; 
String os;
boolean doImage;
boolean doPopup;

void setup() {  
  os = System.getProperty("os.name");
  dir = new File(sketchPath("")); // or dataPath
  selectFolder("Select a folder of .txt files:", "batchSelection");
}

void batchSelection(File selection) {
  if (selection == null) {
    println("No selection (canceled or closed)");
  } else {
    println("Selected:\n    " + selection.getAbsolutePath() + "\n");
    dir = selection; 
    batchMakeTGF(dir, ".txt");
    batchMakeGraphviz(dir, ".txt");
    println("OS: ", os);
    if (os.equals("Mac OS X")) {
      if (doImage == true) {
        batchDotPNG(dir, ".gv");
      }
      if (doPopup == true) {
        batchShowPNG(dir, ".gv");
      }
    }
  }
  exit();
}

void batchMakeTGF(File dir, String ext) {
  File [] files = dir.listFiles();
  for (int i = 0; i <= files.length - 1; i++) {
    String path = files[i].getAbsolutePath();
    if (path.toLowerCase().endsWith(ext)) {
      makeTGF(files[i].getAbsolutePath());
    }
  }
}

void batchDotPNG(File dir, String ext) {
  // String quote = "\"";
  File [] files = dir.listFiles();
  for (int i = 0; i <= files.length - 1; i++) {
    String path = files[i].getAbsolutePath();
    if (path.toLowerCase().endsWith(ext)) {
      // path =  quote + path + quote; 
      // launch("/Applications/Graphviz.app"); // + " " + path);  --OR--  , path);
      exec("/usr/local/bin/dot", "-Tpng", "-O", path); // e.g. dot -Tpng -O  *.gv
    }
  }
}

void batchShowPNG(File dir, String ext) {
  // String quote = "\"";
  File [] files = dir.listFiles();
  for (int i = 0; i <= files.length - 1; i++) {
    String path = files[i].getAbsolutePath();
    if (path.toLowerCase().endsWith(ext)) {
      launch("/Applications/Graphviz.app", path);
    }
  }
}

void makeTGF(String file) {
  Table table = tableLoader(file);
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
  saveStrings(file + ".tgf", tgf.array());
}

void batchMakeGraphviz(File dir, String ext) {
  File [] files = dir.listFiles();
  for (int i = 0; i <= files.length - 1; i++) {
    String path = files[i].getAbsolutePath();
    if (path.toLowerCase().endsWith(ext)) {
      makeGraphviz(files[i].getAbsolutePath());
    }
  }
}

void makeGraphviz(String file) {
  Table table = tableLoader(file);

  StringList graphviz = new StringList(); // GV graphviz dot file lines
  graphviz.append("digraph g{");
  graphviz.append("  graph [rankdir=LR];");
  graphviz.append("  node  [shape=square];");

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
  saveStrings(file + ".gv", graphviz.array());
}

Table tableLoader(String file) {
  Table table = loadTable(file, "tsv"); // // TSV tab separated edge list data - tsv, header

  // remove empty rows
  for (int i=table.getRowCount()-1; i>=0; i--) {
    TableRow row = table.getRow(i);
    boolean full = false;
    for (int j=0; j<row.getColumnCount(); j++) {
      if (row.getString(j)!=null && !row.getString(j).equals("")) {
        full = true;
      }
    }
    if (!full) {
      table.removeRow(i);
    }
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