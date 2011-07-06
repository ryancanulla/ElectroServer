package com.gamebook.util;

import com.electrotank.electroserver5.extensions.BasePlugin;
import com.electrotank.electroserver5.extensions.api.value.EsObject;
import com.electrotank.electroserver5.extensions.api.value.EsObjectRO;

public class TimeStampPlugin extends BasePlugin {

    @Override
    public void init( EsObjectRO parameters ) {
        getApi().getLogger().info( "TimeStampPlugin initialized." );
    }

    @Override
    public final void request( String username, EsObjectRO requestParameters ) {
        EsObject message = new EsObject();
        message.setString( "tm", String.valueOf( System.currentTimeMillis() ) );
        getApi().sendPluginMessageToUser( username, message );
    }

}
