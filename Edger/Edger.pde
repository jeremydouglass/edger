/** edger -- an edge list converter
 * Jeremy Douglass
 * Processing 3.3.5
 * 2017-08-22
 **/

import java.io.ByteArrayInputStream;
import java.util.Arrays;
import org.graphstream.graph.*;
import org.graphstream.algorithm.Toolkit.*;

File workingDir; 
String os;
String actionText;
String styleFile = "gvStyles.txt";
boolean GRAPHVIZ_INSTALLED = true;
int runState;
StringDict labelCodeDict;

void setup() { 
  size(200, 100);
  println("EDGER");
  os = System.getProperty("os.name");
  println("OS: ", os);

  labelCodeDict = new StringDict();
  loadStyle(styleFile);

  switchFolder();

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
    actionText = "REFRESH";
    break;
  case 1:
    fill(255, 0, 0);
    actionText = "   running...";
    runState = 2;
    break;
  case 2:
    loadStyle(styleFile);
    batch(workingDir, ".txt");
    runState = 0;
    delay(500);
    break;
  }
  rect(0, height/4, width, 3*height/4);
  fill(255);
  textSize(14);
  text(actionText, width/2, 7*height/12);
  pushStyle();
  textSize(10);
  textAlign(LEFT, CENTER);
  if (!GRAPHVIZ_INSTALLED) {
    text("(no image output)", 5, height/4 + 10);
  }
  text("STYLE: " + styleFile, 5, height-25);
  text("DIR: " + workingDir.getName(), 5, height-10);
  popStyle();
}

void mouseClicked() {
  runState = 1;
}
void keyPressed() {
  if (key=='p'||key=='P') {
    GRAPHVIZ_INSTALLED = !GRAPHVIZ_INSTALLED;
  }
  if (key=='l'||key=='L') {
    if (runState == 0) {
      switchFolder();
    }
  }
  if (key=='s'||key=='S') {
    if (runState == 0) {
      switchStyleFile();
    }
  }
}

void switchFolder() {
  workingDir = new File(sketchPath("")); // or dataPath
  selectFolder("Select a folder of .txt files:", "selectFolder");
  actionText = "select\n   folder...";
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

void switchStyleFile() {
  selectInput("Select a Graphviz style file:", "selectStyleFile");
  actionText = "select\n   folder...";
}

void selectStyleFile(File selection) {
  if (selection == null) {
    println("No selection (canceled or closed)");
    exit();
  } else {
    println("Selected:\n    " + selection.getAbsolutePath() + "\n");
    styleFile = selection.getAbsolutePath();
    loadStyle(styleFile);
  }
}

void batch(File workingDir, String ext) {
  File [] files = workingDir.listFiles();
  Graph graph;
  GraphUtils gu;

  Table graphStatSummary = new Table();
  graphStatSummary.addColumn("File");
  graphStatSummary.addColumn("Nodes");
  graphStatSummary.addColumn("Diameter");
  graphStatSummary.addColumn("AvgDegree");
  graphStatSummary.addColumn("Top Nodes");
  TableRow summRow;

  // loop through file list 
  for (int i = 0; i < files.length; i++) {
    String fname = files[i].getName();
    if (fname.toLowerCase().endsWith(ext)) {
      Table fileTable = tableLoader(files[i].getAbsolutePath());
      // GV
      String outGraphviz = files[i].getParent() + "/gv/" + fname + ".gv";
      makeGraphviz(outGraphviz, fileTable, fname);
      // TGF
      String outTGF = files[i].getParent() + "/tgf/" + fname + ".tgf";
      makeTGF(outTGF, fileTable);
      // PNG
      if (os.equals("Mac OS X") && GRAPHVIZ_INSTALLED) {
        try {
          String[] params = { "/usr/local/bin/dot", "-Tpng", "-O", outGraphviz }; // e.g. dot -Tpng -O  *.gv
          exec(params);
        } 
        catch (RuntimeException e) {
          // deactivate image output
          println("Deactivating image output: GRAPHVIZ_INSTALLED = false");
          GRAPHVIZ_INSTALLED = false;
          // display error
          println("ERROR:     " + e + "\n");
        }
      }
      if (os.toLowerCase().startsWith("win") && GRAPHVIZ_INSTALLED) {
        try {
          String[] params = { "C:/Program Files (x86)/Graphviz*/bin/dot.exe", "-Tpng", "-O", outGraphviz };
          exec(params);
        } 
        catch (RuntimeException e) {
          // ignore missing image generator
          // println("\n" + e);
        }
      }

      // build GraphStream graph
      graph = loadGraphStream(fname, fileTable);

      // collect graph statistics
      gu = new GraphUtils();
      gu.init(graph);
      gu.compute();

      // display statistics and save to file
      println(gu);      
      String outLog = files[i].getParent() + "/log/" + fname + ".log.txt";
      gu.saveLog(outLog);

      // add key statistics to summary table
      summRow = graphStatSummary.addRow();
      summRow.setString("File", fname);
      summRow.setInt("Nodes", gu.nodeCount);
      summRow.setString("Diameter", nf(gu.diameter, 0, 2));
      summRow.setString("AvgDegree", nf(gu.averageDegree, 0, 2));
      StringList dmap = new StringList();
      for (Node n : gu.degreeMap) {
        if (n.getDegree()>3) {
          dmap.append(n.getId());
        }
      }
      summRow.setString("Top Nodes", join(dmap.array(), ", "));
    }
  }
  // save summary statistics table to working directory
  saveTable(graphStatSummary, workingDir + "/log/_graph_stats.log.csv", "csv");
}

void makeTGF(String outDir, String file) {
  Table table = tableLoader(file);
  makeTGF(outDir, table);
}
void makeTGF(String outDir, Table table) {
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
  // for(String s: tgf.array()){ println(s); }
  saveStrings(outDir, tgf.array());
}


void makeGraphviz(String outDir, String file, String fname) {
  Table table = tableLoader(file);
  makeGraphviz(outDir, table, fname);
}
void makeGraphviz(String outDir, Table table, String fname) {
  StringList graphviz = new StringList(); // GV graphviz dot file lines
  graphviz.append("digraph g{");
  graphviz.append("  graph [" + labelCodeDict.get("graph") + " label=" + "\"" + fname + "\"" + "];");
  graphviz.append("  node  [" + labelCodeDict.get("node") + "];");
  graphviz.append("  edge  [" + labelCodeDict.get("edge") + "];");

  for (TableRow row : table.rows()) {
    String entry = "  "; // indent
    boolean isEdge = row.getString(1)!=null && !trim(row.getString(1)).isEmpty();
    boolean isNode = !isEdge && row.getString(0)!=null && !trim(row.getString(0)).isEmpty();
    boolean hasLabel = row.getString(2)!=null && !trim(row.getString(2)).isEmpty();

    // column 0 - node / edge source
    entry = entry + row.getInt(0);

    // column 1 - edge destination
    if (isEdge) {
      entry = entry + " -> " + row.getInt(1);
    } else {
      entry = entry + "      ";
    }

    // column 2 - label
    if (hasLabel) {
      StringList args = new StringList();
      // apply custom styles based on end of label text
      for (String labelCode : labelCodeDict.keyArray()) {
        if (row.getString(2)!=null && row.getString(2).endsWith(labelCode)) {
          args.append(labelCodeDict.get(labelCode));
        }
      }
      // apply default label styles if no custom styles
      if (args.size() == 0) {
        if (isEdge) {
          args.append(labelCodeDict.get("edgeLabeled"));
        }
        if (isNode) {
          args.append(labelCodeDict.get("nodeLabeled"));
        }
      }
      if (row.getString(2).length()>3) {
        // print long label outside node, leave default node id label
        args.append("xlabel=" + "\"" + row.getString(2).replace("\"", "") + "\"");
      } else {
        // replace default node id with id-plus-label
        args.append("label=" + "\"" + row.getString(0).replace("\"", "") + " " + row.getString(2).replace("\"", "") + "\"");
      }
      // add args to line
      entry = entry + "\t" + "[ " + join(args.array(), ", ") + " ]";
    }
    // end line
    entry = entry + ";";

    // column 3+ - comments
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
        entry = entry + "\t# " + comment.trim();
      }
    }
    graphviz.append(entry);
  }
  // end digraph
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

  // trim whitespace
  for (TableRow row : table.rows()) {
    for (int i=0; i<row.getColumnCount(); i++) {
      row.setString(i, trim(row.getString(i)));
    }
  }

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
  }

  return(table);
}

void launchGraph(String filename) {
  if (os.toLowerCase().startsWith("mac")) {
    launch("/Applications/Graphviz.app", filename);
  }
  if (os.toLowerCase().startsWith("win")) {
    launch("C:/Program Files (x86)/Graphviz2.38/bin/gvedit.exe", filename);
  }
}

void loadStyle(String fname) {
  try {
    Table table = loadTable(fname, "tsv");
    for (TableRow row : table.rows()) {
      if (row.getString(1)!=null && !trim(row.getString(1)).isEmpty()) {
        // println(row.getString(0), row.getString(1));
        labelCodeDict.set(row.getString(0), row.getString(1));
        println(labelCodeDict.get(row.getString(0)));
      }
    }
  }
  catch (NullPointerException e) {
    println("Config file not found.");
    loadStyleDefault();
  }
}

void loadStyleDefault() {
  labelCodeDict.set("graph", "rankdir=LR, ordering=out fontsize=40");
  labelCodeDict.set("node", "colorscheme=spectral9, shape=square");
  labelCodeDict.set("edge", "colorscheme=spectral9, fontcolor=9");
  labelCodeDict.set("nodeLabeled", "style=filled, fillcolor=5");
  labelCodeDict.set("edgeLabeled", "penwidth=2, color=9, fontcolor=9");
  labelCodeDict.set("S", "style=filled, fillcolor=7");
  labelCodeDict.set("E", "style=filled, fillcolor=2");
  labelCodeDict.set("WIN", "style=filled, fillcolor=9");
  labelCodeDict.set("!", "penwidth=2, color=1, fontcolor=1");
}

Graph loadGraphStream(String fname, Table table) {
  Graph graph = new SingleGraph(fname);
  graph.setStrict(false);
  graph.setAutoCreate( true );
  for (TableRow row : table.rows()) {
    boolean isEdge = row.getString(1)!=null && !trim(row.getString(1)).isEmpty();
    boolean isNode = !isEdge && row.getString(0)!=null && !trim(row.getString(0)).isEmpty();
    if (isNode) {
      graph.addNode(row.getString(0));
    }
    if (isEdge) {
      graph.addEdge(row.getString(0)+"_"+row.getString(1), row.getString(0), row.getString(1), true);
    }
  }
  return graph;
}

class GraphUtils implements Algorithm {
  Graph graph;
  int nodeCount;
  String nodeList;
  String edgeList;
  float averageDegree;
  float diameter;
  float diameterDirected;
  int[] degreeDistributionUndirected;
  int[][] degreeRanges = new int[3][3];
  float[] degreeAverages = new float [3];
  int adjacencyMatrix[][];
  ArrayList<Node> degreeMap = new ArrayList();

  void init(Graph g) {
    graph = g;
  }
  void compute() {
    cNodeCount();
    cNodeList();
    cEdgeList();
    cAverageDegree();
    cDiameters();
    cDegreeDistribution();
    cDegreeRanges();
    cAdjacencyMatrix();
    cDegreeMap();
  }

  void cNodeCount() {
    nodeCount = graph.getNodeCount();
  }

  void cNodeList() {
    StringList list = new StringList();
    for (Node n : graph) {
      list.append(n.getId());
    }
    nodeList = join(list.array(), ", ");
  }
  void cEdgeList() {
    StringList list = new StringList();
    for (Edge e : graph.getEachEdge()) {
      list.append(e.getId());
    }
    edgeList = join(list.array(), ", ");
  }
  void cAverageDegree() {
    averageDegree = (float)Toolkit.averageDegree(graph);
  }
  void cDiameters() { // longest direct path
    diameter = (float)Toolkit.diameter(graph);
    diameterDirected = (float)Toolkit.diameter(graph, null, true);
  }
  void cDegreeDistribution() {
    degreeDistributionUndirected = Toolkit.degreeDistribution(graph);
  }
  void cDegreeRanges() {
    int min, inmin, outmin;
    min = inmin = outmin = Integer.MAX_VALUE;
    int max, inmax, outmax;
    max = inmax = outmax = 0;
    int tot, intot, outtot;
    tot = intot = outtot = 0;
    for (Node n : graph) {
      min = Math.min(min, n.getDegree());
      max = Math.max(max, n.getDegree());
      tot = tot + n.getDegree();
      inmin = Math.min(inmin, n.getInDegree());
      inmax = Math.max(inmax, n.getInDegree());
      intot = intot +  n.getInDegree();
      outmin = Math.min(outmin, n.getOutDegree());
      outmax = Math.max(outmax, n.getOutDegree());
      outtot = outtot + n.getOutDegree();
    }
    degreeRanges[0][0] = min;
    degreeRanges[0][1] = max;
    degreeRanges[0][2] = tot;
    degreeRanges[1][0] = inmin;
    degreeRanges[1][1] = inmax;
    degreeRanges[1][2] = intot;
    degreeRanges[2][0] = outmin;
    degreeRanges[2][1] = outmax;
    degreeRanges[2][2] = outtot;
  }
  void cAdjacencyMatrix () {
    adjacencyMatrix = new int[nodeCount][nodeCount];
    for (int i = 0; i < nodeCount; i++) {
      for (int j = 0; j < nodeCount; j++) {
        adjacencyMatrix[i][j] = graph.getNode(i).hasEdgeBetween(j) ? 1 : 0;
      }
    }
  }
  void saveLog(String fname) {
    saveStrings(fname, getLog().array());
  }
  StringList getLog() {
    StringList list = new StringList();
    list.append("----------------------------------------");
    list.append("GRAPH:");
    list.append(graph.getId());
    list.append("----------");
    list.append("");
    list.append("Node Count: " + nodeCount);
    list.append("");
    list.append("Node List:  " + nodeList); 
    // list.append("Edge List:  " + edgeList);
    list.append("");
    list.append("Average degree: " + nf(averageDegree, 0, 2));
    list.append("");
    list.append("Diameter (directed):   " + diameterDirected); // the largest of all the shortest paths from any node to any other node
    list.append("Diameter (undirected): " + diameter); // the largest of all the shortest paths from any node to any other node
    list.append("");
    String[] ddu = {"", ""};
    for (int i = 0; i < degreeDistributionUndirected.length; i++) {
      ddu[0] = ddu[0] + i + " ";
      ddu[1] = ddu[1] + degreeDistributionUndirected[i] + " ";
    }
    list.append("Degree Distribution (undirected): ");
    list.append("   degree: " + ddu[0]);
    list.append("    nodes: " + ddu[1]);
    list.append("");
    list.append("Degree Ranges: ");
    list.append("    min max tot");
    list.append("all " + Arrays.toString(degreeRanges[0]));
    list.append(" in " + Arrays.toString(degreeRanges[1]));
    list.append("out " + Arrays.toString(degreeRanges[2]));
    list.append("");
    list.append("Degree map: (high degree nodes)");
    list.append("#   In  Out Total");    
    for (Node n : degreeMap) {
      if (n.getDegree()>3) {
        list.append(n.getId() + ":  " + n.getInDegree() + "   " + n.getOutDegree() + "   " + n.getDegree());
      }
    }  
    list.append("");
    list.append("");
    return list;
  }
  String toString() {
    StringList list = getLog();    
    return join(list.array(), "\n");
  }
  String printAdjacencyMatrix() {
    StringList list = new StringList();
    list.append("Adjacency Matrix: ");
    for (int[] row : adjacencyMatrix) {
      list.append("   " + Arrays.toString(row));
    }
    return join(list.array(), "\n");
  }
  void cDegreeMap() {
    degreeMap = Toolkit.degreeMap(graph);
  }
}