# How To install BandInMuseScore

## Ubuntu and other Linux
__1.__ Install [MMA Musical Midi Accompaniment]( [https://www.mellowood.ca/mma/) from Ubuntu repository:

    sudo apt-get install mma
	
For other distributions install from your usual repository or package provided at [https://www.mellowood.ca/mma/packages.html](https://www.mellowood.ca/mma/packages.html).

__2.__ [Download](https://github.com/berteh/BandInMuseScore/archive/master.zip) BandInMuseScore plugin, and uncompress it anywhere you like, preferably in your ``Documents/MuseScore3/Plugins`` directory.

__3.__ Optionnaly edit the properties at the beginning of file ``BandInMuseScore3.qml``to match your preferences: default groove name, tempo, and various files locations.


## Windows
__0.__ If you don't already have Python installed you could download a [single zip with Python3.7.2 and MMA19.08 for windows 64bits](https://app.box.com/s/uefkjq7bcgcv40774bo3m0hdwkoscf97) platforms, unzip it in C:\WPython64 (make sure it's not a subfolder) and skip to step 5. Since it's portable you can simply delete the whole directory to uninstall. Or do the whole install yourself (takes less than 10 minutes) with the following instructions:

__1.__ Install a ligthweight portable Python such as [WinPython](https://winpython.github.io/).

The 'Zero' version (without most external librairies and IDE) is about 40Mb download, 110Mb installed. The full version contains many goodies you may find interesting but not need. This plugin has been successully used in Windows8 with [WinPython64-3.7.4.0Zero](https://sourceforge.net/projects/winpython/files/WinPython_3.7/3.7.4.0/WinPython64-3.7.4.0Zero.exe/download).

Install WinPython, recommended in ``C:\WPython64``. Since it's portable you can freely move/rename/delete the whole directory as needed.

__2.__ Download and uncompress the MMA Musical Midi Accompaniment package from its [download page](https://www.mellowood.ca/mma/downloads.html). This plugin has been tested with [MMA v19.08](https://www.mellowood.ca/mma/mma-bin-19.08.tar.gz), other versions should work just fine. Uncompress (un-gzip AND un-tar) it anywhere you like, recommended in ``C:\WPython64\mma-bin-19.08``.

__3.__ Create a new file named ``mma.bat`` in this last directory, with the following content, where the first command makes the script change its working directory to the MMA directory, and the second line runs the ``mma.py`` file with WinPython. You need to update the Python version to the flavour you downloaded.

    cd %~dp0
    ..\python-3.7.4.amd64\python.exe mma.py %1 %2 %3 %5 %6

__4.__ Initialize the database of all available grooves and sequences by running the following command in the MMA directory (via _file explorer > go to MMA diretory (C:\WPython64\mma-bin-19.08) > File > Open Command Prompt_ :

    mma -G

__5.__ [Download](https://github.com/berteh/BandInMuseScore/archive/master.zip) BandInMuseScore plugin, and uncompress it anywhere you like, preferably in your ``MuseScore3/Plugins`` directory.

__6.__ Optionnaly edit the properties at the beginning of file ``BandInMuseScore3.qml``to match your preferences: default groove name, tempo, and various files locations.

## Mac OS/X
Likely very similar to the Linux install, at the beginning of this document. Please provide feedback & guidance if you have any experience.
