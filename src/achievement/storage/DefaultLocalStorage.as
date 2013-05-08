package achievement.storage
{
	import achievement.core.Medal;
	import achievement.properties.Property;
	
	import flash.net.SharedObject;
	import flash.utils.Dictionary;
	
	
	public class DefaultLocalStorage implements IAchievementStorage
	{
		private var _medalStorage:SharedObject;
		private var _propertyStorage:SharedObject;
		
		
		public function DefaultLocalStorage( medalLocation:String = "medalBank_local", propertyLocation:String = "propertyBank_local" )
		{
			_medalStorage = SharedObject.getLocal(medalLocation);
			_propertyStorage = SharedObject.getLocal(propertyLocation);
		}
		
		public function saveProperty(property:Property):void
		{
			_propertyStorage.data["prp_"+property.name] = property;
		}
		
		public function saveMedal(medal:Medal):void
		{
			_medalStorage.data["mdl_"+medal.name] = medal;
			_medalStorage.flush();
		}
		
		public function loadMedals():Dictionary
		{
			var medalBank:Dictionary = new Dictionary();
			
			for( var medalName:String in _medalStorage.data )
			{
				var medal:Medal = _medalStorage.data[medalName];
				medalBank[medal.name] = medal;
			}
			
			return medalBank;
		}
		
		public function loadProperties():Dictionary
		{
			var propertyBank:Dictionary = new Dictionary();
			
			for( var propName:String in _propertyStorage.data )
			{
				var property:Property = _propertyStorage.data[propName];
				propertyBank[property.name] = property;
			}
			
			return propertyBank;
		}
		
		public function flush():void
		{
			_propertyStorage.flush();
		}
		
		
	}
	
}