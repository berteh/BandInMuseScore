import MuseScore 3.0
import FileIO 3.0
import QtQuick 2.2
import QtQuick.Dialogs 1.1

MuseScore {
  menuPath: "Plugins.BandInMuseScore3"
  description: "Generate a band-like accompaniment on the basis of Chords and Grooves, using MMA Midi Accompaniment."
  version: "3.0"
  requiresScore: true
   
  // change default settings to your liking here.
  // ************************************************************
  // *
  property string defaultGroove : "Folk";
  property int defaultTempo : 120;
  property bool discardRepeats: false; //set to true for enabling copy-paste of generated midi into leadsheet despite repeat bars.

  //for Linux and MacOS users
  property string nixMMAPath : "/tmp/MMAtemp.mma"; // absolute and writeable,  no '~'
  property string nixMIDPath : "/tmp/MMAtemp.mid"; // absolute and writeable,  no '~'
  property string nixMMACommand : "mma "; //add -r, or more, for debug infos

  //for  Windows users
  property string winMMAPath : "C:/temp/MMAtemp.mma"; // absolute and writeable
  property string winMIDPath : "C:/temp/MMAtemp.mid"; // absolute and writeable
  property string winMMACommand : "C:/WPython64/mma-bin-19.08/mma.bat "; //add -r, or more, for debug infos

  // *
  // ********* thank you, that's all for the settings ***********

      
  property int measureIndex: 1;
  property var measureChords : [];
  property int currentTick: 0;
  //property int measureTick: 0; // provision for handling chords position in the measure
    
  property string mmaPath : Qt.platform.os == "windows" ?winMMAPath:nixMMAPath;  // values for Qt.platform.os are at https://doc.qt.io/qt-5/qml-qtqml-qt.html#platform-prop
  property string midPath : Qt.platform.os == "windows" ?winMIDPath:nixMIDPath;
  property string mmaCommand : Qt.platform.os == "windows" ?"cmd.exe /c "+winMMACommand:nixMMACommand;
  
  
  QProcess {
    id: proc
  }

  FileIO {
    id: mmaFile
    source: mmaPath
  }
  
  FileIO {
    id: midFile
    source: midPath
  }
  
  MessageDialog {
    id: generationCompleteDialog
    title: "Success"
    text: "MMA accompaniment is ready for you in MuseScore.\nThe source MMA file is available at "+mmaPath;
    onAccepted: {
        Qt.quit();
    }
    Component.onCompleted: visible = false
  }
  
  MessageDialog {
    id: midFailureDialog
    title: "Generation incomplete"
    text: "MMA accompaniment is ready for you, but we could not generate the MIDI file from it.\n\n"+
           "Please check path settings in script, or run the 'mma' command manually:\n  "+
           mmaCommand+" -f "+midPath+" "+mmaPath+"\n\n"+
           "The source MMA file is available at "+mmaPath;
    onAccepted: {
        Qt.quit();
    }
    Component.onCompleted: visible = false
  }

  
      
  function chordsToMMA() {
    //turns sequence of chords buffered into measureChords into MMA code, and empties measureChords.
    
    var res = "";
    var chord = measureChords.shift();
    while (chord) {
           res += ' '+chord["txt"];              
           //TODO handle measure lenghts and chords position (via chord["tick"])
           chord = measureChords.shift();
    }
    console.log("MMA chords buffer is: "+res);
    return(res);
  }
  
  function isMMAdirective(text) {
    //TODO detect the text elements that should not be fed to MMA
    
    return(true);
  }
  
  function exportElement(elt) {
  
      var result = "";
      if (elt) {
        //console.log(elt.userName() +" at: " + segment.tick); 
        switch(elt.type){
          case Element.HARMONY:
            if (! elt.text) {
              console.log('Chord symbol is not yet parsed by MuseScore, forcing transpose to force parsing. Ugly workaround, you got better?');
              //transpose up and back down to make sure harmony.text property is initialized.
              cmd("transpose-up");
              cmd("transpose-down");
            }
            console.log('buffering Harmony '+elt.text+" at " + currentTick);
            measureChords.push({ txt : elt.text, tick: currentTick })
            break;
          case Element.BAR_LINE:
          case Element.BARLINE: //saw this alternative syntax elsewhere, seems useless.
            if (currentTick > 0) //skip printing chords buffer when the Bar line is the first symbol of the track.
                  result = '\n'+ measureIndex++ +' '+ chordsToMMA() ;            
            if (elt.subtypeName() === "end") {
                  result += '\ncut ';
            } else if (!discardRepeats && elt.subtypeName() === "start-repeat") {
                  result += '\nRepeat';
            } else if (!discardRepeats && elt.subtypeName() === "end-repeat") {
                  result += '\nRepeatEnd';
            } else if (!discardRepeats && elt.subtypeName() === "end-start-repeat") {
                  result += '\nRepeatEnd\nRepeat';
            } 
            break;
          case Element.TEMPO_TEXT:
            result = '\nTempo '+elt.tempo*60;
            break;
/*          case Element.KEYSIG:
            result = '\nKeySig '+elt.key(); //todo can't read content of key from API?
            break;
*/
          case Element.TIMESIG:
            result = '\nTimeSig '+elt.timesig.numerator+' '+elt.timesig.denominator;;//2.0 was numerator+' '+elt.denominator;
            break;
          case Element.STAFF_TEXT:
            if(isMMAdirective(elt.text))
              result = '\n'+elt.text;
            else
              result = '\n/* '+elt.text+' */';
            break;
          //case Element.DYNAMIC:
          //case Element.CHORD:
          default:
            console.log(" - skipped " + elt._name());               
        } // end switch
      } //end if elt
      return result;
  } // end function exportElement
  
  
  
  function writeMMA(text){
    var test = mmaFile.write(text);
    //console.log("writing: "+text); // 
    //TODO give users feedback if failure to write
  }
  
  function runMMA(){
      var cmd = mmaCommand+" -f "+midPath+" "+mmaPath;
      console.log("generating MIDI file with command: "+cmd);
      proc.start(cmd);
      var val = proc.waitForFinished(30000);
      if (val) {
           console.log(proc.readAllStandardOutput());
           return(true);
      } else {
          console.log("Generation of MIDI file failed, please check paths in script, or run MMA manually on file "+mmaPath);
          return(false);
      }
  }
    
  onRun: {
      if (typeof curScore === 'undefined')
         Qt.quit();
      //TODO quit if no Harmony in score... or not to allow generation from only Staff Texts ?
          
      //generate MMA
      console.log("Generating MMA for "+curScore.scoreName);
      measureIndex = 1;
      var mmaTxt = "// "+curScore.title+", "+curScore.composer+"\n"+
                   "// MMA Midi Accompaniment generated from MuseScore\n"+
                   "// github.com/berteh/BandInMuseScore  -  www.mellowood.ca/mma/\n"+
                   "\nTempo "+defaultTempo+
                   "\nGroove "+defaultGroove+"\n"; //default values for mandatory directives, likely overriden later in Score.
        
        //for (var track = 0; track < curScore.ntracks; ++track) {
        var track = 0;
           console.log("exporting track "+track);
           var segment = curScore.firstSegment();            
           
           while (segment) {
             currentTick = segment.tick;
              //Harmony, Tempo and other dynamics are annotations on the segment.
              var anns = segment.annotations;
              if (anns && (anns.length > 0)) {
                //console.log("with " + anns.length + " annotations ");
                for (var annc = 0; (annc < anns.length); annc++) {
                  mmaTxt += exportElement(anns[annc]);
                }
              }              
              //save MMA text for current segment
              mmaTxt += exportElement(segment.elementAt(track));
                            
              segment = segment.next;
            } // end while segment
      //} // end for staff/track
      
      console.log("\nMMA:\n\n" + mmaTxt);
      
      mmaFile.remove();
      midFile.remove();
      writeMMA(mmaTxt);
      //generate MIDI
      runMMA();
      //open MIDI
      if(midFile.exists()) {
        var leadScore = curScore;
      //TODO merge lead and accompaniment, set title, composer and more.
        var acc = readScore(midPath);
        acc.setMetaTag("title", leadScore.title+" - MMA"); //todo how to display title on score ?
        acc.setMetaTag("composer", leadScore.composer+" with MMA");
        generationCompleteDialog.open();
      }
      else
        midFailureDialog.open();        
      
      Qt.quit();
   } // end onRun
 	
}
