package achievement.events
{
	import flash.events.Event;
	
	
	public class PropertyEvent extends Event
	{
		
		
		public static const COMPLETE:String = "propertyComplete";
		
		
		public function PropertyEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		
		
	}
	
	
	
}