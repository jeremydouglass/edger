/** edger -- an edge list converter
 * Jeremy Douglass
 * Processing 3.3.5
 **/

import java.io.ByteArrayInputStream;
import java.util.Arrays;
import org.graphstream.graph.*;
import org.graphstream.algorithm.Toolkit.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

Path workingPath;
File workingDir; 
ArrayList<File> workingDirs;
boolean recurse;
String os;
String actionText;
Path stylePath;
File styleFile;
String settingsFile = "settings.txt";
boolean graphvizInstalled = true;
boolean tgfOutput = true;
boolean jekyllOutput = false;
boolean graphDirected = true;
int runState;
StringDict labelCodeDict;
StringDict settingsDict;
boolean ignoreBadRows = false;
boolean exitWhenDone;

void setup() { 
  size(200, 200);
  os = System.getProperty("os.name");

  // detect command line invocation -- requires a throwaway
  // placeholder argument, e.g. "exit"
  // e.g.
  //     processing-java --sketch=`pwd`/Edger --run exit
  if (args != null) {

    // default run-and-quit command line behavior
    runState = 1;
    exitWhenDone = true;
    // override with arguments
    for (String arg : args) {
      if ("nomake".equals(arg)) {
        runState=0;
      }
      if ("noexit".equals(arg)) {
        // 
        exitWhenDone=false;
      }
    }
  }

  settingsDict = new StringDict();
  loadSettings(settingsFile);

  workingPath = Paths.get(settingsDict.get("folder"));
  if (Files.isDirectory(workingPath)) {
    workingDir = workingPath.toFile();
  } else {
    workingPath = Paths.get(sketchPath() + "/" + settingsDict.get("folder"));
    if (Files.isDirectory(workingPath)) {
      workingDir = workingPath.toFile();
    } else {
      workingDir = new File(sketchPath() + "/data");
    }
  }

  workingDirs = listFilesRecursive(workingDir.getAbsolutePath());

  stylePath = Paths.get(settingsDict.get("styles"));
  if (Files.isRegularFile(stylePath)) {
    styleFile = stylePath.toFile();
  } else {
    stylePath = Paths.get(sketchPath() + "/" + settingsDict.get("styles"));
    if (Files.isRegularFile(stylePath)) {
      styleFile = stylePath.toFile();
    } else {
      styleFile = new File(sketchPath() + "/" + "gvStyles.txt");
    }
  }

  println("EDGER");
  println("   OS: ", os);
  println("  Dir: ", workingDir.getName());
  println("Style: ", styleFile.getName());

  labelCodeDict = new StringDict();
  loadStyles(styleFile);

  textAlign(CENTER, CENTER);
  noStroke();
}

void draw() {
  background(192);
  color runc = color(0, 0, 0);

  pushStyle();
  fill(0);
  rect(0, 0, width, height/8);
  fill(255);
  textSize(18);
  text("EDGER", width/2, height/16);
  popStyle();

  switch(runState) {
  case 0:
    runc = color(0, 0, 255);
    actionText = "MAKE GRAPHS";
    if (exitWhenDone) {
      exit();
    }
    break;
  case 1:
    runc = color(255, 0, 0);
    actionText = "   running...";
    runState = 2;
    break;
  case 2:
    runc = color(255, 255, 0);
    loadStyles(styleFile);
    if (recurse) {
      workingDirs = listFilesRecursive(workingDir.getAbsolutePath());
      for (File f : workingDirs) {
        println("Processing directory: " + f.getAbsolutePath());
        batch(f, ".txt");
      }
    } else {
      batch(workingDir, ".txt");
    }
    runState = 0;
    delay(500);
    break;
  }

  pushStyle();
  translate(0, height/8);
  fill(runc);
  rect(0, 0, width, 3*height/8);
  fill(255);
  textSize(20);
  text(actionText, width/2, 3*height/16);
  noFill();
  stroke(255);
  rect(10, 10, width-20, 3*height/8-20, 7);
  popStyle();

  pushStyle();
  translate(0, 3*height/8);
  fill(64);
  rect(0, 0, width, height/4);
  if (!graphvizInstalled) {
    text("(no image output)", 5, height/4 + 10);
  }
  fill(255);
  textSize(12);
  textAlign(LEFT, CENTER);
  text("DIR: " + workingDir.getName(), 15, height/8);
  noFill();
  stroke(255);
  rect(10, 10, width-20, height/4-20, 7);
  popStyle();

  pushStyle();
  translate(0, height/4);
  fill(96);
  rect(0, 0, width, height/4);
  fill(255);
  textSize(12);
  textAlign(LEFT, CENTER);
  text("STYLE: " + styleFile.getName(), 15, height/8);
  noFill();
  stroke(255);
  rect(10, 10, width-20, height/4-20, 7);
  popStyle();
}

void mouseClicked() {
  if (mouseY < height/2) {
    runState = 1;
  }
  if (mouseY > height/2 && mouseY < 3*height/4) {
    switchFolder();
  }
  if (mouseY > 3*height/4) {
    switchStyleFile();
  }
}
void keyPressed() {
  if (key=='l'||key=='L') {
    if (runState == 0) {
      println("Load working folder:");
      switchFolder();
    }
  }
  if (key=='p'||key=='P') {
    if (runState == 0) {
      graphvizInstalled = !graphvizInstalled;
      println("Graphviz export:", graphvizInstalled);
    }
  }
  if (key=='r'||key=='R') {
    if (runState == 0) {
      recurse=!recurse;
      println("Recurse directories: ", recurse);
    }
  }
  if (key=='s'||key=='S') {
    if (runState == 0) {
      println("Load style file:");
      switchStyleFile();
    }
  }
  if (key=='t'||key=='T') {
    if (runState == 0) {
      tgfOutput = !tgfOutput;
      println("TGF output: ", tgfOutput);
    }
  }
  if (key=='d'||key=='D') {
    if (runState == 0) {
      graphDirected = !graphDirected;
      println("Graphviz directed: ", graphDirected);
    }
  }
  if (key=='j'||key=='J') {
    if (runState == 0) {
      jekyllOutput = !jekyllOutput;
      println("Jekyll output: ", jekyllOutput);
    }
  }
}

void switchFolder() {
  selectFolder("Select a folder of .txt files:", "selectFolder", workingDir);
  actionText = "select\n   folder...";
}

void selectFolder(File selection) {
  if (selection == null) {
    println("No selection (canceled or closed)");
    // exit();
  } else {
    println("Selected:\n    " + selection.getAbsolutePath() + "\n");
    workingDir = selection;
    workingDirs = listFilesRecursive(workingDir.getAbsolutePath());

    settingsDict.set("folder", selection.getAbsolutePath());
    PrintWriter output = createWriter(settingsFile);
    settingsDict.write(output);
    output.flush();
    output.close();
  }
}

void switchStyleFile() {
  selectInput("Select a Graphviz style file:", "selectStyleFile");
  actionText = "select\n   folder...";
}

void selectStyleFile(File selection) {
  if (selection == null) {
    println("No selection (canceled or closed)");
    // exit();
  } else {
    println("Selected:\n    " + selection.getAbsolutePath() + "\n");
    styleFile = selection;

    settingsDict.set("styles", selection.getAbsolutePath());
    PrintWriter output = createWriter(settingsFile);
    settingsDict.write(output);
    output.flush();
    output.close();    

    loadStyles(styleFile);
  }
}

void batch(File workingDir, String ext) {
  File [] files = workingDir.listFiles();
  if (files == null || files.length == 0) {
    println("No files found.");
    return;
  }
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
      Table fileTable = loadSparseEdgeListToTable(files[i].getAbsolutePath());
      // GV
      String outGraphviz = files[i].getParent() + "/graphiz/" + fname + ".gv";
      String outImage    = files[i].getParent() + "/images/" + fname + ".gv.png";
      makeGraphviz(outGraphviz, fileTable, fname, graphDirected);

      if (tgfOutput) {
        // TGF
        String outTGF = files[i].getParent() + "/tgf/" + fname + ".tgf";
        makeTGF(outTGF, fileTable);
      }

      if (jekyllOutput) {
        // Jekyll Markdown files
        String jfname = fname.split(" ")[0];
        if (fname.length() > 5) {
          jfname = fname.substring(0, 5);
        } else {
          jfname = fname;
        }
        String outjmd = files[i].getParent() + "/jmd/" + jfname + ".md";
        makeJekyllCollectionsMarkdown(outjmd);
      }

      // PNG
      String graphvizBinary = "";
      if (os.equals("Mac OS X") && graphvizInstalled) {
        if (graphDirected) {
          graphvizBinary="/usr/local/bin/dot";
        } else {
          graphvizBinary="/usr/local/bin/neato";
        }
        try {
          String[] params = { graphvizBinary, "-Tpng", "-o", outImage, outGraphviz }; // e.g. dot -Tpng -O *.gv  --or--  dot -Tpng -o bar.png foo.gv
          exec(params);
        } 
        catch (RuntimeException e) {
          // deactivate image output
          println("Deactivating image output: graphvizInstalled = false");
          graphvizInstalled = false;
          // display error
          println("ERROR:     " + e + "\n");
        }
      }
      if (os.toLowerCase().startsWith("win") && graphvizInstalled) {
        if (graphDirected) {
          graphvizBinary="C:/Program Files (x86)/Graphviz2.38/bin/dot.exe";
        } else {
          graphvizBinary="C:/Program Files (x86)/Graphviz2.38/bin/neato.exe";
        }
        try {
          String[] params = { graphvizBinary, "-Tpng", "-o", outImage, outGraphviz };
          exec(params);
        } 
        catch (RuntimeException e) {
          // deactivate image output
          println("Deactivating image output: graphvizInstalled = false");
          graphvizInstalled = false;
          // display error
          println("ERROR:     " + e + "\n");
        }
      }

      // build GraphStream graph
      graph = loadGraphStream(fname, fileTable);

      // collect graph statistics
      gu = new GraphUtils();
      gu.init(graph);
      gu.compute();

      // display statistics
      // println(gu);

      // save statistics to file
      String outLog = files[i].getParent() + "/logs/" + fname + ".log.txt";
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
  saveTable(graphStatSummary, workingDir + "/logs/_graph_stats.log.csv", "csv");
}

/**
 * because Jekyll can't map collection detail pages out
 * dynamically from data files without plugins, generate
 * a stub page for each graph to tie the id (file slug)
 * together with book details and graph gallery resource files
 **/
void makeJekyllCollectionsMarkdown(String outDir) {
  StringList jmd = new StringList();
  // for(String s: tgf.array()){ println(s); }
  jmd.append("---");
  jmd.append("layout: default");
  jmd.append("---");
  jmd.append("{% include gamebook_detail.html id=page.slug %}");
  jmd.append("{% include gamebook_gallery.html id=page.slug %}");
  saveStrings(outDir, jmd.array());
}

void makeTGF(String outDir, String file) {
  Table table = loadSparseEdgeListToTable(file);
  makeTGF(outDir, table);
}
void makeTGF(String outDir, Table table) {
  StringList tgf = new StringList();
  StringList tgfnodes = new StringList();
  StringList tgfedges = new StringList();

  for (TableRow row : table.rows()) {

    // not edge
    if (row.getString(1)==null || trim(row.getString(1)).isEmpty()) {
      // and not empty (node)
      if (row.getString(0)!=null && !trim(row.getString(0)).isEmpty()) {
        String node = "" + row.getString(0);
        // and has name
        if (row.getString(2)!=null) {
          node = node + "\t" + row.getString(2);
        }
        tgfnodes.append(node);
      }
      // edge
    } else {
      String edge = "" + row.getString(0) + "\t" + row.getString(1);
      // and has name
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


void makeGraphviz(String outDir, String file, String fname, boolean directed) {
  Table table = loadSparseEdgeListToTable(file);
  makeGraphviz(outDir, table, fname, directed);
}
void makeGraphviz(String outDir, Table table, String fname, boolean directed) {
  StringList graphviz = new StringList(); // GV graphviz dot file lines
  String edgeType = "";
  if (directed) {
    graphviz.append("digraph g{");
    edgeType = "->";
  } else {
    graphviz.append("graph g{");
    edgeType = "--";
  }
  String g = "";
  if (!"".equals(fname)) {
    g = g + " label=" + "\"" + fname + "\" ";
  }
  if (!labelCodeDict.get("graph", "").isEmpty()) {
    g = g + labelCodeDict.get("graph", "");
  }
  if (!"".equals(g)) {
    graphviz.append("  graph [" + g + "];");
  }
  if (!labelCodeDict.get("node", "").isEmpty()) {
    graphviz.append("  node  [" + labelCodeDict.get("node") + "];");
  }
  if (!labelCodeDict.get("edge", "").isEmpty()) {
    graphviz.append("  edge  [" + labelCodeDict.get("edge") + "];");
  }

  for (TableRow row : table.rows()) {
    String entry = "  "; // indent
    switch(row.getString("type")) {
    case "NODE":
      entry = entry + row.getString(0);
      break;
    case "EDGE":
      entry = entry + row.getString(0) + " " + edgeType + " " + row.getString(1);
      break;
    case "COMMENT":
      entry = entry + "// " + row.getString(3);
      break;
    case "EMPTY":
      // entry = entry + "\n";
      break;
    case "ERROR":
      continue;
    default:
      throw new IllegalArgumentException("Invalid line type: " + row.getString("type"));
    }

    // attributes
    StringList attrs = new StringList();
    boolean hasLabel = row.getString(2)!=null && !trim(row.getString(2)).isEmpty();
    if (hasLabel) {
      // print label outside node, leave default in-node label as id
      attrs.append("xlabel=" + "\"" + row.getString(2).replace("\"", "") + "\"");

      // apply custom styles based on end of label text
      for (String labelCode : labelCodeDict.keyArray()) {
        if (row.getString(2)!=null && row.getString(2).endsWith(labelCode)) {
          attrs.append(labelCodeDict.get(labelCode));
        }
      }

      // apply default label styles if no custom styles
      if (attrs.size() == 0) {
        if (row.getString("type").equals("EDGE")) {
          String el = labelCodeDict.get("edgeLabeled", "");
          if (!el.isEmpty()) {
            attrs.append(el);
          }
        }
        if (row.getString("type").equals("NODE")) {
          String nl = labelCodeDict.get("nodeLabeled", "");
          if (!nl.isEmpty()) {
            attrs.append(nl);
          }
        }
      }
      // add attrs to line
      entry = entry + "\t" + "[ " + join(attrs.array(), ", ") + " ]";
    }
    // end line
    if (!row.getString("type").equals("EMPTY")) {
      entry = entry + ";";
    }

    // line comments
    boolean hasLineComment = (!row.getString("type").equals("COMMENT") && row.getString(3)!=null && !trim(row.getString(3)).isEmpty());
    if (hasLineComment) {
      entry = entry + "\t// " + row.getString(3);
    }
    graphviz.append(entry);
  }
  // end digraph
  graphviz.append("}\n");
  // display graphviz output
  // for (String s : graphviz) { println(s); }
  saveStrings(outDir, graphviz.array());
}

/**
 * Takes a TSV tab-separated file string (no header)
 * that describes a sparse edge list with comments
 * pre-processes it for graph parsing (empty rows, padding)
 * and returns the filestring as a Table.
 */
Table loadSparseEdgeListToTable(String fileName) {
  // clean file line strings
  StringList flist = new StringList(loadStrings(fileName));
  for (int i=flist.size() - 1; i >= 0; i--) {
    String s = trim(flist.get(i));
    // delete empty lines
    if (s.equals(null) || s.isEmpty()) {
      flist.set(i, " ");
      continue;
    }
    // indent comment-only lines to fourth column regardless of position
    if (trim(s).charAt(0)=='#' || trim(s).startsWith("//")) {
      flist.set(i, "\t\t\t" + trim(s));
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

  // collapse extra column contents back to the 4th (comment) column
  for (TableRow row : table.rows()) {
    StringList cs = new StringList();
    // list comment columns
    for (int col=3; col<row.getColumnCount()-1; col++) {
      if (row.getString(col)==null || row.getString(col).equals("")) {
        continue;
      } else {
        cs.append(row.getString(col));
      }
    }
    // combine comment columns
    String c = trim(join(cs.array(), " | "));
    // trim comment markers
    while (c.startsWith("//") || c.startsWith("#")) {
      if (c.startsWith("//")) {
        c = trim(c.substring(2));
      } else if (c.startsWith("#")) {
        c = trim(c.substring(1));
      }
    }
    // trim multi-line comment style on a single line
    if (c.startsWith("/**") && c.endsWith("**/")) {
      c = c.substring(3, c.length() - 3);
    }
    row.setString(3, c);
  }

  // delete all extra columns
  table.setColumnCount(4);

  // add full columns
  if (table.getColumnCount()<1) {
    table.addColumn("source");
  } else {
    table.setColumnTitle(0, "source");
  }
  if (table.getColumnCount()<2) {
    table.addColumn("destination");
  } else {
    table.setColumnTitle(1, "destination");
  }
  if (table.getColumnCount()<3) {
    table.addColumn("label");
  } else {
    table.setColumnTitle(2, "label");
  }
  if (table.getColumnCount()<4) {
    table.addColumn("comment");
  } else {
    table.setColumnTitle(3, "comment");
  }

  // trim whitespace
  for (TableRow row : table.rows()) {
    for (int i=0; i<row.getColumnCount(); i++) {
      row.setString(i, trim(row.getString(i)));
    }
  }

  table.addColumn("type", Table.STRING);

  String headnode = "";
  int counter = 0;
  for (TableRow row : table.rows()) {
    counter++;
    boolean[] cells = new boolean[4];
    for (int i=0; i<cells.length; i++) {
      cells[i] = !(row.getString(i)==null || row.getString(i).equals(""));
    }
    // update headnode
    if (cells[0]) {
      headnode=row.getString(0);
    }
    if (cells[0] && !cells[1]) {
      row.setString("type", "NODE");
      continue;
    }
    if (cells[0] && cells[1]) {
      row.setString("type", "EDGE");
      continue;
    }
    if (!cells[0] && cells[1]) {
      // sparse edge -- fill in with previous headnode
      if (!headnode.equals("")) {
        row.setString(0, headnode);
        row.setString("type", "EDGE");
      } else {
        row.setString("type", "ERROR");
        row.print();
        throw new RuntimeException("Sparse edge with no headnode! In file: " + fileName);
      }
      continue;
    }
    if (!cells[0] && !cells[1] && cells[2]) {
      // sparse label -- fill in node with previous headnode
      if (!headnode.equals("")) {
        row.setString(0, headnode);
        row.setString("type", "NODE");
      } else {
        row.setString("type", "ERROR");
        row.print();
        throw new RuntimeException("Sparse label with no headnode! In file: " + fileName);
      }
      continue;
    }    
    if (!cells[0] && !cells[1] && !cells[2] && cells[3]) {
      row.setString("type", "COMMENT");
      continue;
    }
    if (!cells[0] && !cells[1] && !cells[2] && !cells[3]) {
      row.setString("type", "EMPTY");
      continue;
    }

    // catch specific bad data
    if (!cells[0] && !cells[1] && cells[2]) {
      String err = "Label with no node or edge!\n  In file: " + fileName + "\n  on line: " + counter;
      if (ignoreBadRows) {
        println(err);
        row.setString("type", "ERROR");
        continue;
      } else {
        throw new RuntimeException(err);
      }
    }

    // catch general bad data
    String err = "Row of unknown type!\n  In file: " + fileName + "\n  on line: " + counter;
    if (ignoreBadRows) {
      println(err);
      row.setString("type", "ERROR");
    } else {
      throw new RuntimeException(err);
    }
  }

  /*
  // detect alpha nodes
   //
   // these could be logged, or checked for specific warnings
   // such as labels accidentally appearing as node names
   // alternately, there could be a strict mode (numbers only)
   // ...or a semi-strict required list of node names...?
   
   for (TableRow row : table.rows()) {
   boolean[] cells = new boolean[4];
   for (int i=0; i<cells.length; i++) {
   cells[i] = !(row.getString(i)==null || row.getString(i).equals(""));
   }
   if (cells[0] && !isNaturalNumber(row.getString(0))){
   println("Node NaN: ", row.getString(0));
   }
   if (cells[1] && !isNaturalNumber(row.getString(1))){
   println("Edge NaN: ", "   ", row.getString(1));
   }
   }
   */

  // table.print();
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

void loadStyles(File file) {
  StringDict newlabelCodeDict = new StringDict();
  try {
    Table table = loadTable(file.getAbsolutePath(), "tsv");
    for (TableRow row : table.rows()) {
      if (!row.getString(0).isEmpty() && !row.getString(1).isEmpty()) {
        // println(row.getString(0), row.getString(1));
        newlabelCodeDict.set(row.getString(0), row.getString(1));
      }
    }
    labelCodeDict = newlabelCodeDict;
  }
  catch (NullPointerException e) {
    println("Config file not found.");
  }
  // newlabelCodeDict.print();
}

void loadSettings(String fname) {
  StringDict newSettingsDict = new StringDict();
  try {
    Table table = loadTable(fname, "tsv");
    for (TableRow row : table.rows()) {
      if (row.getString(1)!=null && !trim(row.getString(1)).isEmpty()) {
        // println(row.getString(0), row.getString(1));
        newSettingsDict.set(row.getString(0), row.getString(1));
      }
    }
    settingsDict = newSettingsDict;
  }
  catch (NullPointerException e) {
    println("Settings not found! Falling back to defaults.");
    newSettingsDict.set("folder", "data");
    newSettingsDict.set("styles", "gvBlank.txt");
    settingsDict = newSettingsDict;
  }
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
    if (degreeDistributionUndirected!=null) {
      for (int i = 0; i < degreeDistributionUndirected.length; i++) {
        ddu[0] = ddu[0] + i + " ";
        ddu[1] = ddu[1] + degreeDistributionUndirected[i] + " ";
      }
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

void printFiles(String dir) {
  ArrayList<File> allFiles = listFilesRecursive(dir);
  for (File f : allFiles) {
    println("Name: " + f.getName());
    println("Full path: " + f.getAbsolutePath());
    println("Is directory: " + f.isDirectory());
    println("Size: " + f.length());
    println("-----------------------");
  }
}

// Function to get a list of all files in a directory and all subdirectories
// https://processing.org/examples/directorylist.html
ArrayList<File> listFilesRecursive(String dir) {
  ArrayList<File> fileList = new ArrayList<File>(); 
  recurseDir(fileList, dir);
  return fileList;
}

// Recursive function to traverse subdirectories
// https://processing.org/examples/directorylist.html
void recurseDir(ArrayList<File> a, String dir) {
  File file = new File(dir);
  if (file.isDirectory() && !file.getName().startsWith(".") && !file.getName().equals("logs")) {
    // If you want to include directories in the list
    a.add(file);  
    File[] subfiles = file.listFiles();
    for (int i = 0; i < subfiles.length; i++) {
      // Call this function on all files in this directory
      recurseDir(a, subfiles[i].getAbsolutePath());
    }
  } else {
    // directories only!
    // a.add(file);
  }
}

// Check if a string is a number.
boolean isNaturalNumber(String str) {
  if (str == null) {
    return false;
  }
  int length = str.length();
  if (length == 0) {
    return false;
  }
  for (int i = 0; i < length; i++) {
    char c = str.charAt(i);
    if (c < '0' || c > '9') {
      return false;
    }
  }
  return true;
}
// as per https://stackoverflow.com/a/237204/7207622
boolean isInteger(String str) {
  if (str == null) {
    return false;
  }
  int length = str.length();
  if (length == 0) {
    return false;
  }
  int i = 0;
  if (str.charAt(0) == '-') {
    if (length == 1) {
      return false;
    }
    i = 1;
  }
  for (; i < length; i++) {
    char c = str.charAt(i);
    if (c < '0' || c > '9') {
      return false;
    }
  }
  return true;
}