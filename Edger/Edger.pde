/** edger -- an edge list converter
  * Jeremy Douglass
  * Processing 3.3.5
  * 2017-07-29
 **/

Table table;        // TSV tab separate edge list file
PrintWriter output; // GV graphviz dot file

void setup() {  
  table = loadTable("example.txt", "tsv"); // tsv, header
  output = createWriter("example.txt.gv"); 
  println(table.getRowCount() + " total rows in table"); 

  output.println("digraph g{");
  for (TableRow row : table.rows()) {
    String edge = "  " + row.getInt(0) + " -> " + row.getInt(1) + "\t[label=" + row.getString(2) + "]";
    output.println(edge);
  }
  output.println("}");
  output.flush();  // Writes the remaining data to the file
  output.close();  // Finishes the file
}