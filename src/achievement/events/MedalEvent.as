package achievement.events
{
	import flash.events.Event;
	
	
	public class MedalEvent extends Event
	{
		
		public static const UNLOCKED:String = "medalUnlocked";
		
		
		public function MedalEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		
	}
	
	
}