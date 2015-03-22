//
//  RecordedAudio.swift
//  PitchPerfect
//
//  Created by OLIVER HAGER on 3/16/15.
//  Copyright (c) 2015 OLIVER HAGER. All rights reserved.
//

import Foundation

// Recorded audio file information (title and path)
class RecordedAudio: NSObject {
    //title
    var title: String!
    
    //path
    var recordingFilePath: NSURL!
    
    /// initialize object
    ///
    /// :param: String! title
    /// :param: NSURL! path to recorded audio file
    /// :returns: Nothing useful
    init(title: String!, recordingFilePath: NSURL!) {
        self.title = title
        self.recordingFilePath=recordingFilePath
    }
}