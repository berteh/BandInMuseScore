//import QtQuick 2.2
import MuseScore 3.0
 import FileIO 3.0

MuseScore {
  menuPath: "Plugins.BandInMuseScore"
  description: "Generate a band-like accompaniment on the basis of Chords and Grooves, using MMA Midi Accompaniment."
  version: "3.0"
  requiresScore: true
   
  //change default settings to your liking here.
  //************************************************************
  property string defaultGroove : "Folk";
  property int defaultTempo : 120;
  property bool discardRepeats: false; //set to true for enabling copy-paste of generated midi into leadsheet despite repeat bars.
  property string mmaPath : "C:/temp/MMAtemp.mma";
  property string midPath : mmaPath + ".mid ";
  property string mmaCommand: "cmd.exe /c C:/WPython64/mma-bin-19.08/mma.bat -f "+ midPath + " "; //add -r, or more, for debug infos
  // ********* thank you that's all for the settings ***********
  
  property int measureIndex: 1;
  property var measureChords : [];
  property int currentTick: 0;
  //property int measureTick: 0; // provision for handling chords position in the measure
  
  QProcess {
    id: proc
  }

   FileIO {
        id: mmaFile
        source: mmaPath
    }
  
    
  function chordsToMMA() {
    //TODO handle measure lenghts and chords position (via chord["tick"])
    var res = "";
    var chord = measureChords.shift();
    while (chord) {
           res += ' '+chord["txt"];              
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
    console.log("writing: "+text); // 
    //TODO give users feedback if failure to write
    
  }
  
  function runMMA(){
      //TODO fix error: "No data created. Did you remember to set a groove/sequence?"
      console.log("running MMA is not automatic yet. Groove and styles likely not found. Kindly run the following command directly:\n  $ "+mmaCommand+" "+mmaFile.source);
      proc.start(mmaCommand+" "+mmaFile.source);
      var val = proc.waitForFinished(30000);
      if (val)
           console.log(proc.readAllStandardOutput());
           return(true);
      else
          console.log("no output from proc");
          return(false);
  }
    
  onRun: {
      if (typeof curScore === 'undefined')
         Qt.quit();
      //TODO quit if no Harmony in score... or not to allow generation from only Staff Texts ?
      
      //init
      measureIndex = 1;
      var mmaTxt = "//MMA Midi Accompaniment generated from MuseScore\n"+
                   "//"+curScore.title+", "+curScore.composer+"\n"+
                   "\nTempo "+defaultTempo+"\nGroove "+defaultGroove+"\n"; //default values for mandatory, likely overriden later in Score.
  
      
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
              
              //current segment content
              mmaTxt += exportElement(segment.elementAt(track));
                            
              segment = segment.next;
            } // end while segment
      //} // end for staff/track
      
      console.log("\nMMA:\n\n" + mmaTxt);
      
      writeMMA(mmaTxt);
      var gotMID = runMMA();
      //TODO import mid in musescore and add original tracks to imported score. set its title, composer and more., if(gotMID)
      
      Qt.quit();
   } // end onRun
 	
}
