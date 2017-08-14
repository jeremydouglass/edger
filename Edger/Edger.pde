/** edger -- an edge list converter
  * Jeremy Douglass
  * Processing 3.3.5
  * 2017-07-29
 **/

Table table;         // TSV tab separated edge list data
StringList graphviz; // GV graphviz dot file lines
StringList tgf;      // TGF trivial graph format
StringList tgfnodes; // TGF trivial graph format nodes
StringList tgfedges; // TGF trivial graph format edges

void setup() {  
  table = loadTable("example.txt", "tsv"); // tsv, header
  table.sort(0);
  println(table.getRowCount() + " rows in table\n");

  graphviz = new StringList();
  makeGraphviz();

  tgf = new StringList();
  tgfnodes = new StringList();
  tgfedges = new StringList();
  makeTGF();
  
  exit();
}

void makeTGF() {
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
  tgfnodes.append("#");
  for (int i=0; i<tgfedges.size(); i++) {
    tgfnodes.append(tgfedges.get(i));
  }
  saveStrings("example.txt.tgf", tgfnodes.array());
}

void makeGraphviz() {
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
  saveStrings("example.txt.gv", graphviz.array());
}