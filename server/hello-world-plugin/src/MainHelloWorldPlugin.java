import com.electrotank.electroserver5.extensions.BasePlugin;
import com.electrotank.electroserver5.extensions.api.value.EsObject;
import com.electrotank.electroserver5.extensions.api.value.EsObjectRO;


public class MainHelloWorldPlugin extends BasePlugin {
	
	@Override
	public void request(String playerName, EsObjectRO requestOb) {
		getApi().getLogger().debug(playerName + " Sent Request");
		
		if (requestOb.getString("action").equals("RequestHello")) {
			
			EsObject sendOb = new EsObject();
			sendOb.setString("action", "HelloSent");
			sendOb.setString("message", "Hello!");
			getApi().sendPluginMessageToUser(playerName, sendOb);
		}
	}

}
