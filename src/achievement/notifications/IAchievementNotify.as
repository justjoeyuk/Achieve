package achievement.notifications
{
	import achievement.core.Medal;
	
	public interface IAchievementNotify
	{
		function notify( medal:Medal ):void;
	}
	
}