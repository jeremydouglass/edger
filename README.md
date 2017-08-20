# edger: an edge list converter

### *record simple graphs, convert into multiple formats*

**Edger** is a simple batch processor for textual graph data. It takes a directory of text files, parses them, and outputs graph files, images, and stats logs for them.

It was developed for use in data processing of interactive narratives (such as gamebooks).

## Install

Edger is implemented as a cross-platform Processing(Java) sketch -- it can be run in the Processing Development Environment (PDE) or exported from PDE to a standalone application.

1. Install Processing
2. Download Edger
3. (optional) Install Graphviz for Mac or Windows to enable PNG image output.
4. (optional) Export an application
   -  Launch Edger.pde in Processing
   -  `File > Export Application` to create a Mac or Win app.

Edger relies on Graphviz being installed separately in order to perform for image rendering, although it will run without it. It also uses the GraphStream core for summary statistics -- which is built-in.

## Use

To use Edger as a Processing sketch:

1. Launch Edger.pde
2. Press Run (">")
3. Select working directory (location of txt files
4. Edger will process files and produce output
   - Click floating windoe to re-process files
   - SPACE to toggle PNG image generation
   - ESC or Quit when finished

To use Edger after exporting it as an application:

1. Launch Edger.app / Edger.exe
2. Select working directory (location of txt files
3. Edger will process files and produce output
   - Click floating windoe to re-process files
   - SPACE to toggle PNG image generation
   - ESC or Quit when finished

On run, Edger requests a working directory, and processes all .txt files in that directory. Original text files are untouched, with output files are replaced each re-run. Note that if source file names change then old graph and image outputs may be left behind -- although this will be visible by checking file dates.

## Output

For each input text file `name.txt`, Edger outputs:

-  `/gv/name.gv`: a Graphviz DOT file (for use with Graphviz)
-  `/tgf/name.tgf`: a Trivial Graph Format file (for use with yEd)
-  `/log/name.log`: a log files of graph descriptive statics
-  `/gv/name.gv.png`: an image, rendered by Graphviz

In addition, for each batch of files processed it produces:

-  `/log/_graph_stats.log.csv`: a summary file of key statistics 

## Input

Edger processes a directory of plain text files (.txt). Specifically, these text files are *sparse edge lists*, a custom graph data format designed for quick data entry. This means that Edger supports the simple edge list format:

```
1 2
2 3
2 4
```

...as well as numerous extensions to the edge list format, including:

-  whitespace
-  graph labels
-  code comments
-  sparse entries

Here is an example of a sparse edge list:

```
# File is tab-separated (tsv)
# Filename ends in .txt

# These are edges, with or without comments
1 2
2 3 edge  # a labeled edge w/comment
3   node  # a labeled node w/comment
4 5
4 8   # separate node lines are optional

# These are whole-line comments
     # ## Comments begin with '#' after any amount of whitespace
# Blank may be used to organize material

# repeat edges may be specified
5 6
5 7
5 8

# repeat edges may have an implied first node
6 9 choice1
  10  choice2
  11  choice3
9 12  c1
  13  c2

# nodes and edges may be listed in any order
1   Start
12    End1
13    End2

# unlabeled node lines
# previous node 2 unaffected
2
# new floating node 100 created 
100

```

-------


