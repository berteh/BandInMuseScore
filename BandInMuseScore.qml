import QtQuick 2.0
import MuseScore 1.0

MuseScore {
  menuPath: "Plugins.BandInMuseScore"
  description: "Generate a band-like accompaniment on the basis of Chords and Grooves, using MMA Midi Accompaniment."
  version: "1.0"
  
  property int measureIndex: 1;
  property var measureChords : [];
  property bool discardRepeats: false; //set to true for enabling copy-paste of generated midi into leadsheet with repeat bars.
  //property int measureTick: 0; // provision for handling chords position in the measure
  
  QProcess {
    id: proc
  }

  
    
  function chordsToMMA() {
    //TODO handle measure lenghts and chords position (via chord["tick"])
    var res = "";
    var chord = measureChords.shift();
    while (chord) {
           res += ' '+chord["txt"];              
           chord = measureChords.shift();
    }
    console.log("MMA chords: "+res);
    return(res);
  }
  
  
  
  function exportElement(elt) {
  
      var result = "";
      if (elt) {
        //console.log(elt.userName() +" at: " + segment.tick); 
        switch(elt.type){
          case Element.HARMONY:
            if (! elt.text) {
              console.log('ERROR parsing Harmony: Chord symbol is not yet parsed by MuseScore, please parse them all by transposing the whole score to Unison and run the plugin again. ');
              Qt.quit();
            }
            console.log('buffering Harmony '+elt.text+" at " + elt.parent.tick);
            measureChords.push({ txt : elt.text, tick: elt.parent.tick })
            break;
          case Element.BAR_LINE:
          case Element.BARLINE: //saw this alternative syntax elsewhere, seems useless.
            if (elt.parent.tick > 0) //in case a repeatbar is the first symbol)
                  result = '\n'+ measureIndex++ +' '+ chordsToMMA() ;            
            if (elt.subtypeName() === "end") {
                  result += '\ncut ';
            } else if (!discardRepeats && elt.subtypeName() === "start-repeat") {
                  result += '\nRepeat';
            } else if (!discardRepeats && elt.subtypeName() === "end-repeat") {
                  result += '\nRepeatEnd';
            } else if (!discardRepeats && elt.subtypeName() === "end-start-repeat") {
                  result += '\nRepeatEnd\nRepeat';
            } else {
                  //
            }
            break;
          case Element.TEMPO_TEXT:
            result = '\nTEMPO '+elt.tempo*60;
            break;
/*          case Element.KEYSIG:
            result = '\nKeySig '+elt.key(); //todo can't read content of key from API?
            break;
*/
          case Element.TIMESIG:
            result = '\nTimeSig '+elt.numerator+' '+elt.denominator;
            break;
          //case Element.DYNAMIC:
          //case Element.CHORD:
          //TODO include some generic text support to allow for other custom grooves codes.
          default:
            console.log(" - skipped " + elt._name());               
        } // end switch
      } //end if elt
      return result;
  } // end function exportElement
  
  
  
  function writeMMA(fileUrl, text){

    var request = new XMLHttpRequest();
    request.open("DELETE", fileUrl, false);
    request.open("PUT", fileUrl, false);
    request.send(text);
    console.log("MMA file written to "+fileUrl);
          
    return request.status;
  }
  
  function runMMA(file){
      //TODO fix error: "No data created. Did you remember to set a groove/sequence?"
      console.log("running MMA is not automatic yet. Groove and styles likely not found. Kindly run the following command directly:\n  $ mma ./MMAtemp.mma  & musescore ./MMAtemp.mid");
      proc.start("mma "+file);
      var val = proc.waitForFinished(30000);
      if (val)
           console.log(proc.readAllStandardOutput());
  }
    
  onRun: {
      if (typeof curScore === 'undefined')
         Qt.quit();
      //TODO quit if no Harmony in score
      
      //transpose up and back down to make sure all chords are parsed 
      //by MuseScore and their text property is set.
      cmd("transpose-up");
      cmd("transpose-down");
      
      //init
      measureIndex = 1;
      var mmaTxt = "//MMA Midi Accompaniment generated from MuseScore\n"+
                   "//"+curScore.title+", "+curScore.composer+"\n"+
                   "\nTEMPO 120\nGroove Folk\n";
                      
           
/*
      //work on active selection or full score
      var cursor = curScore.newCursor();
      var startStaff;
      var endStaff;
      var endTick = curScore.lastSegment.tick + 1;
      var fullScore = false;
      
      cursor.rewind(1); // beginning of selection
      if (!cursor.segment) { // no selection
         fullScore = true;
         startStaff = 0; // start with 1st staff
         endStaff  = curScore.nstaves - 1; // and end with last
      } else {
         startStaff = cursor.staffIdx;
         cursor.rewind(2); // end of selection
         if (cursor.tick != 0) // selection does not include last measure 
            endTick = cursor.tick;
         endStaff = cursor.staffIdx;
      }
      console.log("range is staves " + startStaff + " to " + endStaff + " - end tick: " + endTick)

      for (var staff = startStaff; staff <= endStaff; staff++) {
            cursor.rewind(1); // beginning of selection
            cursor.staffIdx = staff;

            if (fullScore)  // no selection
               cursor.rewind(0); // beginning of score

            while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                   var elt = cursor.element;
             
  */
        //for (var track = 0; track < curScore.ntracks; ++track) {
        var track = 0;
           console.log("exporting track "+track);
           var segment = curScore.firstSegment();            
           
           while (segment) {
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
      
      writeMMA("./MMAtemp.mma",mmaTxt);
      runMMA("./MMAtemp.mma");
      //TODO generate mid, import mid in musescore and add original tracks to imported score. set its title, composer and more.
      
   } // end onRun
   
  	
}
