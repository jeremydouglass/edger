/** edger -- an edge list converter
  * Jeremy Douglass
  * Processing 3.3.5
  * 2017-07-29
 **/

File dir; 

void setup() {  
  dir = new File(sketchPath("")); // or dataPath
  selectFolder("Select a folder of .txt files:", "batchSelection");
}

void batchSelection(File selection) {
  if (selection == null) {
    println("No selection (canceled or closed)");
  } else {
    println("Selected: " + selection.getAbsolutePath());
    dir = selection; 
    batchMakeTGF(dir, ".txt");
    batchMakeGraphviz(dir, ".txt");
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

void makeTGF(String file) {
  Table table = loadTable(file, "tsv"); // // TSV tab separated edge list data - tsv, header
  // table.sort(0);
  println(table.getRowCount() + " rows in table\n");

  StringList tgf = new StringList();
  StringList tgfnodes = new StringList();
  StringList tgfedges = new StringList();

  for (TableRow row : table.rows()) {
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
  Table table = loadTable(file, "tsv"); // // TSV tab separated edge list data - tsv, header
  // table.sort(0);
  println(table.getRowCount() + " rows in table\n");

  StringList graphviz = new StringList(); // GV graphviz dot file lines
  graphviz.append("digraph g{");
  graphviz.append("  graph [rankdir=LR];");
  graphviz.append("  node  [shape=square];");

  for (TableRow row : table.rows()) {
    String edge = "  " + row.getInt(0);
    if (row.getString(1)==null || row.getString(1).equals("")) {
      edge = edge + "      ";
    } else {
      edge = edge + " -> " + row.getInt(1);
    }
    if (row.getString(2)!=null) {
      edge = edge + "\t" + "[label=" + row.getString(2) + "]";
    }
    graphviz.append(edge + ';');
  }
  graphviz.append("}\n");
  for (String s : graphviz) {
    println(s);
  }
  saveStrings(file + ".gv", graphviz.array());
}