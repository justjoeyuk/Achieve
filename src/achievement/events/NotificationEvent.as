package achievement.events
{
	import flash.events.Event;
	
	public class NotificationEvent extends Event
	{
		
		public static const NOTIFICATION_CLICKED:String = "unlock_notification_clicked";
		
		public function NotificationEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
	}
}