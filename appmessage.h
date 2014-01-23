//
//  appmessage.h
//  PebbleRoute
//
//  Created by Remus Lazar on 22.01.14.
//  Copyright (c) 2014 Remus Lazar. All rights reserved.
//

#ifndef PebbleRoute_appmessage_h
#define PebbleRoute_appmessage_h

// AppMessage attributes keys
enum {
    APPMESSAGE_KEY_ROUTESTEP_INDEX,
    APPMESSAGE_KEY_ROUTESTEP_DISTANCE,
    APPMESSAGE_KEY_ROUTESTEP_INSTRUCTIONS,
    APPMESSAGE_KEY_UPDATE_INDEX, // index of the current step
    APPMESSAGE_KEY_UPDATE_DISTANCE, // remaining distance in current step
    APPMESSAGE_KEY_UPDATE_TOTAL_DISTANCE, // remaining total distance to destination
    APPMESSAGE_KEY_UPDATE_ALERT, // alert the user
	APPMESSAGE_KEY_READY, // tell the watch that we are ready
};

// AppMessage action keys
enum {
    APPMESSAGE_REQUEST_GET_ROUTE,
    APPMESSAGE_REQUEST_REROUTE,
};


#endif
