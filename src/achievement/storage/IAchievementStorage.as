package achievement.storage
{
	import achievement.core.Medal;
	import achievement.properties.Property;
	
	import flash.utils.Dictionary;

	public interface IAchievementStorage
	{
		
		function saveProperty( property:Property ):void;
		function flush():void;
		function saveMedal( medal:Medal ):void;
		function loadMedals():Dictionary;
		function loadProperties():Dictionary;
		
	}
}