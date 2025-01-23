# WWU_ERP
User interface for ERP analysis of EEG data.

This toolbox provides a front end interface for ERP analysis.  It operates at a 
study level by applying processing steps to all subjects. Most of the backend analysis uses
eeglab (https://sccn.ucsd.edu/eeglab/index.php).

### Dependencies
ESMA requires that the following MATLAB toolboxes be installed and on the MATLAB path.
- eeglab (https://sccn.ucsd.edu/eeglab/index.php) with
  - Fieldtrip plugin
  - ICA Label plugin
  - BIOSIG Plugin
- Mass Univariate Toolbox written by Groppe, Urbach & Kutas can
  be found at https://openwetware.org/wiki/Mass_Univariate_ERP_Toolbox
- FMUT toolbox is the  factorial model extension of the Mass
  Univariate Toolbox written by Eric Fields and can be downloaded
  from https://github.com/ericcfields/FMUT.

### Installation Instructions
  1. Download and install each of the dependencies according to their individual instructions and add them to the Matlab path.  For EEGLAB, you should use the plugins interface to makes sure that the Fieldtrip, ICALabel and BIOSIG plugins are installed.
  2. Download ESMA and place it in a folder of your choosing.  Add the installation to the Matlab path.  Do not add the subfolders to the path, ESMA will do that internally.
  3. To start ESMA type esma in the Matlab command window.

### Data Structure
ESMA requires your data files to be organized according to a specific structure.
Data Path:  The data for all the experiments ESMA displays must be located within a single data folder.  The main data folder must be arranged as follows.
- It must contain a *STUDIES* folder that stores the metadeta for all the studies located in the data folder.  If this folder does not exist it will be created when you create your first study.
- It must contain one folder for each experiment in the study.  These folders will be identified when building the study, but ESMA will not create them.  Within these experiment folders the data should be organized by participant with one folder per participant.  Although any naming convention is valid, it is probably a good practice to name the folder *'S1', 'S2' ... 'SN'* where 1, 2 ... N represent the subject number.  Each subject folder must contain all the data files for that subject.  It is critical that each of those files have the exact same filename.  For example, if the Biosemi data file for participant one is called "RAW.bdf', the same file for all other participants must use the same name convention.  It is this requirement that allows ESMA to automatically process the files from all participants.

A single data folder can contain as many experiments as you like.  All the experiments in the data folder will be accessible from the main ESMA interface and can be selected in the top dropdown box.
It is also possible to create more than one data folder (e.g. for different users).  There is a menu option in the main ESMA interace *[ESMA -> Change data path]*  that allows for the user to dynamically toggle between data folders.


### File Creation
During analysis, ESMA will generate a potentially large number of new files.  New files that contain individual subject data will be placed in the folder for that subject.
Files that represent the aggregation of data across particpiants will be placed in a new folder called *'across participant'*.

All the files available for an experiment are displayed in the central display tree.  Files are organized according to recognized data types with include:
- Biosemi files: bdf format files.
- Continuous EEG:  These are non-epoched data files created from bdf files by EMSA.  They are recognized by their *'cnt* extension.  Because the format is identical to an EEGLAB continueous file, any EEGLAB continuous file can be read by changing its extension from *'.set'* to *'.cnt'.
- Epoched Trial Data:  epoched time domain data created from continuous files by ESMA.  These files are recognized by the *'epc'* extension. Because these files are the same format as EEGLAB ERPLAB format, other files should be readable by changing the extension.
