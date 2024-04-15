import Foundation

class ScaleMatcher : ObservableObject {
    var lastMatchTime:Date?
    var nextMatchIndex = 0
    var matches:[NoteMatch] = []
    var topMidi:Int = 0
    var lastGoodMidi:Int?
    var wrongCount = 0
    var correctCount = 0
    var firstNoteMatched = false
    var mismatchCount = 0
    var mismatchesAllowed = 0
    
    init(scale:Scale, mismatchesAllowed:Int) {
        var num = 0
        matches = []
        for midi in scale.notes {
            matches.append(NoteMatch(noteNumber: num, midi: midi))
            num += 1
        }
        ///downwards
        for index in stride(from: scale.notes.count - 2, through: 0, by: -1) {
            matches.append(NoteMatch(noteNumber: num, midi: scale.notes[index]))
            num += 1
        }
        topMidi = scale.notes.max() ?? 0
        self.mismatchesAllowed = mismatchesAllowed
    }
    
    func initialise() {
        firstNoteMatched = false
        lastGoodMidi = nil
        mismatchCount = 0
        wrongCount = 0
        nextMatchIndex = 0
    }
    
    func midiToNoteNum(midi: Int) -> Int {
        let nameIndex = (midi + 48 - matches[0].midi) % 12
        return nameIndex
    }
    
    func makeMidiOctaves(midi: Int) -> [Int] {
        let res = [midi-36, midi-24, midi-12, midi, midi+12, midi+24]
        return res
    }
    
    func match(timestamp:Date, midis:[Int]) -> MatchType {
        if nextMatchIndex >= matches.count  {
            return MatchType(.dataIgnored, "after_scale")
        }
//        if !firstNoteMatched {
//            if Double(amplitude) < self.startAmplitude { //TODO
//                return MatchType(.dataIgnored, "before_scale, amp:\(self.startAmplitude)")
//            }
//        }
        
        let requiredMidi = matches[nextMatchIndex].midi
        let requiredNoteNumber = self.midiToNoteNum(midi: requiredMidi)
//        if midis[0]==91 && midis[1]==93 {
//            print("==========")
//        }
        for midiIndex in 0..<midis.count {
            let midi = midis[midiIndex]
            if let lastGoodMidi = lastGoodMidi {
                if makeMidiOctaves(midi: lastGoodMidi).contains(midi) {
                    self.mismatchCount = 0
                    if midiIndex > midis.count - 1 {
                        return MatchType(.dataIgnored, "already_matched, looking_for midi:\(requiredMidi)") // noteNum:[\(requiredNoteNumber)]")
                    }
                }
            }
            
            let requiredMidisOctave = [requiredMidi-24, requiredMidi-12, requiredMidi, requiredMidi+12, requiredMidi+24]
            if requiredMidisOctave.contains(midi) {
                matches[nextMatchIndex].matchedTime = timestamp
                nextMatchIndex += 1
                self.firstNoteMatched = true
                self.mismatchCount = 0
                self.lastGoodMidi = midi
                return MatchType(.correct, "required_midi:\(requiredMidi) matched:\(midi) noteNum:[\(requiredNoteNumber)]")
            }
            if mismatchCount == self.mismatchesAllowed {
                if firstNoteMatched {
                    nextMatchIndex += 1
                }
                wrongCount += 1
                return MatchType(.wrongNote, "required_midi:\(requiredMidi) OR_Octaves:\(makeMidiOctaves(midi: requiredMidi)) noteNum:[\(requiredNoteNumber)] wrongCount:\(self.wrongCount)")
            }
            else {
                self.mismatchCount += 1
            }
        }
        return MatchType(.dataIgnored, "looking_for midi:\(requiredMidi) noteNum:[\(requiredNoteNumber)]  mismatchCount:\(mismatchCount)")
    }

    func noteNumToName(num:Int) -> String {
        var ret = ""
        switch num {
        case 0:
            ret = "C"
        case 2:
            ret = "D"
        case 4:
            ret = "E"
        case 5:
            ret = "F"
        case 7:
            ret = "G"
        case 9:
            ret = "A"
        case 11:
            ret = "B"
        default:
            ret = String(num)
        }
        return ret
    }
    
    func stats() -> String {
        var missing = 0
        correctCount = 0
        for match in self.matches {
            if match.matchedTime == nil {
                missing += 1
                //Logger.shared.log(self, "Missing note number:\(match.noteNumber) midi:\(match.midi)")
            }
            else {
                correctCount += 1
            }
        }

        var lastMatchTime:Date?
        var ctr = 0
        var total = 0.0
        //get tempo
        for match in self.matches {
            if match.matchedTime == nil {
                break
            }
            if let lastMatchTime = lastMatchTime {
                let delta = match.matchedTime!.timeIntervalSince1970 - lastMatchTime.timeIntervalSince1970
                total += delta
                ctr += 1
            }
            lastMatchTime = match.matchedTime
        }
        let tempo = total / Double(ctr)
        let tempo1 = tempo > 0 ? Int(60.0 / tempo) : 0
        //return "Errors:\(wrongCount) Correct:\(correctCount) Tempo\(tempo1)"
        return "ScaleMatcher, =====>Missing:\(missing)   Correct:\(correctCount)   Tempo:\(tempo1) \(tempo1/4)  MismatchesAllowed:\(self.mismatchesAllowed)"
    }
    
//    func matchNew1(timestamp:Date, frequency:Float, asc:Bool) -> MatchType {
////        if nextMatchIndex >= matches.count  {
////            return MatchType(.seen)
////        }
//        let midi = frequencyToMIDI(frequency: frequency)
//
//        var c = 0
//        let midPoint = self.matches.count / 2
//        var matched1:Set<Int> = []
//
//        if ascending {
//            for i in 0...midPoint {
//                let match = self.matches[i]
//                if midi == match.midi {
//                    if match.matchedTime == nil {
//                        match.matchedTime = timestamp
//                        if midi == topMidi {
//                            ascending = false
//                            matched1 = []
//                        }
//                        return MatchType(.correct)
//                    }
//                    matched1.insert(midi)
//                }
//                if midi > match.midi {
//                    if match.matchedTime == nil {
////                        if !match.missNoted {
////                            match.missNoted = true
////                            let status = MatchType(.wrongNote)
////                            status.missedMidis = [match.midi]
////                            return status
////                        }
//                    }
//                }
//                if midi < match.midi {
//                    if match.matchedTime == nil {
//                        return MatchType(matched1.contains(midi) ? .dataIgnored : .wrongNote)
//                    }
//                }
//            }
//        }
//        else {
//            for i in midPoint..<self.matches.count {
//                let match = self.matches[i]
//                if midi == match.midi {
//                    if match.matchedTime == nil {
//                        match.matchedTime = timestamp
//                        return MatchType(.correct)
//                    }
//                    matched1.insert(midi)
//                }
//                if midi > match.midi {
//                    if match.matchedTime == nil {
//                        return MatchType(matched1.contains(midi) ? .dataIgnored : .wrongNote)
//                    }
//                }
//            }
//        }
//        return MatchType(.dataIgnored)
//    }
}
