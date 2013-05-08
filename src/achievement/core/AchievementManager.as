package achievement.core
{
	import achievement.events.MedalEvent;
	import achievement.events.PropertyEvent;
	import achievement.notifications.IAchievementNotify;
	import achievement.properties.Property;
	import achievement.properties.TimedProperty;
	import achievement.storage.DefaultLocalStorage;
	import achievement.storage.IAchievementStorage;
	
	import flash.errors.IllegalOperationError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.registerClassAlias;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	

	public class AchievementManager extends EventDispatcher
	{
		
		private static var _instance:AchievementManager = new AchievementManager();
		private var _propertyBank:Dictionary;
		private var _medalBank:Dictionary;
		private var _onUnlock:Function;
		private var _storage:IAchievementStorage;
		private var _saveTimeInSeconds:uint = 5;
		private var _saveTimer:Timer;
		private var _changedProperties:Vector.<Property>;
		private var _notifier:IAchievementNotify;
		private var _devMode:Boolean = false;
		
		
		/**
		 * The constructor for AchievementManager. This should not be called outside 
		 * of the Class, else an error will be thrown.
		 */
		public function AchievementManager()
		{
			if( _instance ) throw new IllegalOperationError("AchievementManager can only be obtained through: AchievementManager.getInstance()", 004);
			registerClassAlias("Medal", Medal);
			registerClassAlias("Property", Property);
			registerClassAlias("TimedProperty", TimedProperty);
			registerClassAlias("Dictionary", Dictionary);
			
			_saveTimer = new Timer(_saveTimeInSeconds * 1000);
			_saveTimer.addEventListener(TimerEvent.TIMER, saveProperties);
			_saveTimer.start();
			_storage = new DefaultLocalStorage();
			_medalBank = _storage.loadMedals();
			_propertyBank = _storage.loadProperties();
			_changedProperties = new Vector.<Property>();
		}
		
		
		/**
		 * <p>This will return an AchievementManager. The 
		 * AchievementManager is a Singleton so only gets 
		 * initialized once.</p>
		 * 
		 * @return -- Returns the AchievementManager.
		 */
		public static function getInstance():AchievementManager
		{
			return _instance;
		}
		
		
		/**
		 * <p>Creates a Medal and registers it to the AchievementManager. 
		 * Just as the Properties are tracked and stored, so are 
		 * Medals.</p>
		 * 
		 * @param medalName -- The medal to be registered (keep it short).
		 * @param medalDescription -- The description of the medal.
		 * @param properties -- (optional) The list of properties attached to the medal.
		 * @param pointsValue -- (optional) The points the medal is worth.
		 * @param hidden -- If true, the User will not know how to unlock (secret).
		 * 
		 * @see createProperty
		 */
		public function createMedal( medalName:String, medalDescription:String, properties:Array = null, pointsValue:uint = 0, hidden:Boolean = false ):void
		{
			if( _medalBank[medalName] != null ) return;
			
			var medal:Medal = Medal.create(medalName, medalDescription, pointsValue, hidden);
			
			if( properties != null )
			{
				for each( var name:String in properties )
				{
					medal.assignProperty(getProperty(name));
					getProperty(name).addOwner(medal);
				}
			}
			_medalBank[medalName] = medal;
			medal.addEventListener(MedalEvent.UNLOCKED, onMedalUnlock);
		}
		
		
		/**
		 * <p>Manually override the properties and 
		 * unlock a Medal yourself. Properties are 
		 * recommended as they are tracked and saved.</p>
		 * 
		 * @param medalName -- The name of the Medal you wish to unlock.
		 */
		public function unlockMedal( medalName:String ):void
		{
			_medalBank[medalName].unlockMedal();
		}
		
		
		/**
		 * <p>Notifies the user of an unlocked medal by using 
		 * the notifier <code>achievementManager.notifier</code>.</p>
		 * 
		 * @param medal -- The medal that was unlocked.
		 */
		public function notify(medal:Medal):void
		{
			if( _notifier == null ) throw IllegalOperationError("No notifier attached. Please attach a new notifier. 'achievementManager.notifier = new DefaultUnlockNotifier()' or such.");
			if( !medal.isUnlocked ) throw IllegalOperationError("You may not notify for an achievement that is still locked.");
			
			_notifier.notify(medal);
		}
		
		
		/**
		 * <p>Creates a Property and registers it to the AchievementManager. 
		 * Just as the Medals are tracked and stored, so are 
		 * Properties.</p>
		 * 
		 * @param propertyName -- The property to be registered.
		 * @param startValue -- The starting value of the property.
		 * @param finalValue -- The final value of the property.
		 * @param condition -- The condition the property will be tested against. 
		 * <code>Property.DEFAULT</code> is the default (equal or greater than).
		 * @param removeWhenInactive -- If true, Property will be deleted 
		 * if all Medals using the Property are unlocked.
		 * 
		 * @see createMedal
		 */
		public function createProperty( propertyName:String, startValue:Object, finalValue:Object,
										condition:String = Property.DEFAULT, removeWhenInactive:Boolean = true ):void
		{
			if( _propertyBank[propertyName] ){ return; }
			var property:Property = Property.create(propertyName, startValue, finalValue, condition, removeWhenInactive);
			
			_propertyBank[propertyName] = property;
			property.addEventListener(PropertyEvent.COMPLETE, onPropertyComplete);
		}
		
		
		/**
		 * <p>Creates a Property and registers it to the AchievementManager. 
		 * Just as the Medals are tracked and stored, so are 
		 * Properties. Timed properties revert to the previous state when time 
		 * expires.</p>
		 * 
		 * @param propertyName -- The property to be registered.
		 * @param startValue -- The starting value of the property.
		 * @param finalValue -- The final value of the property.
		 * @param timeInMillis -- The time before property resets in milliseconds. (1000 = 1 second)
		 * @param condition -- The condition the property will be tested against. 
		 * <code>Property.DEFAULT</code> is the default (equal or greater than).
		 * @param removeWhenInactive -- If true, Property will be deleted 
		 * if all Medals using the Property are unlocked.
		 * 
		 * @see registerMedal
		 */
		public function createTimedProperty( propertyName:String, startValue:Object, finalValue:Object, timeInMillis:uint,
											 condition:String = Property.DEFAULT, removeWhenInactive:Boolean = true):void
		{
			if( _propertyBank[propertyName] ) { return; }
			var property:TimedProperty = TimedProperty.create(propertyName, startValue, finalValue, timeInMillis, condition, removeWhenInactive);
			
			_propertyBank[propertyName] = property;
			property.addEventListener(PropertyEvent.COMPLETE, onPropertyComplete);
		}
		
		
		/**
		 * <p>Assigns a property to a Medal, which means that 
		 * the property and any others on the Medal must all 
		 * be completed for the Medal to be unlocked.</p>
		 * 
		 * @param propertyName -- The name of the Property to assign.
		 * @param medalName -- The name of the Medal to assign to.
		 */
		public function assignProperty( propertyName:String, medalName:String ):void
		{
			var medal:Medal = getMedal(medalName);
			var property:Property = getProperty(propertyName);
			property.addOwner(medal);
			medal.assignProperty(property);
			
			if( !_devMode )
			{
				_storage.saveMedal(medal);
				_storage.saveProperty(property);
				_storage.flush();
			}
		}
		
		
		/**
		 * <p>Saves the properties every few seconds defined by 
		 * the programmer by using <code>saveInterval</code> which is 
		 * set to 5 by default</p>
		 * 
		 * @param event -- The event passed into the Handler
		 */
		private function saveProperties( event:TimerEvent ):void
		{
			var numChanged:int = _changedProperties.length;
			if( numChanged == 0 ) return;
			
			if( !_devMode )
			{
				for( var i:int = 0; i < _changedProperties.length; i++ )
				{
					_storage.saveProperty(_changedProperties[i]);
				}
				
				_storage.flush();
			}
			_changedProperties.length = 0;
		}
		
		
		/**
		 * <p>Gets the Medal associated with the name you
		 * pass into the function.</p>
		 * 
		 * @param medalName -- The name of the Medal to retrieve.
		 * 
		 * @return -- The Medal with the name you specified.
		 */
		private function getMedal( medalName:String ):Medal
		{
			if( _medalBank[medalName] == null ) throw new IllegalOperationError("There is no Medal called: " + medalName, 002);
			return _medalBank[medalName];
		}
		
		
		/**
		 * <p>Gets the Property associated with the name you
		 * pass into the function.</p>
		 * 
		 * @param propertyName -- The name of the Property to retrieve.
		 * 
		 * @return -- The Property with the name you specified.
		 */
		private function getProperty( propertyName:String ):Property
		{
			if( _propertyBank[propertyName] == null ) throw new IllegalOperationError("There is no Achievement Property called: " + propertyName + " .. Maybe you are trying to access a completed property although you made it when 'removeWhenInactive' was set to true?", 003);
			return _propertyBank[propertyName];
		}
		
		
		/**
		 * <p>Enables you to change the final value 
		 * or the condition for the completion of the 
		 * property.</p>
		 * 
		 * @param propertyName -- The name of the property to reset.
		 * @param finalValue -- The new final value of the property.
		 * @param condition -- The completion condition for the property.
		 * @param removeWhenInactive -- Delete the property when it's complete or not.
		 * 
		 */
		public function resetProperty( propertyName:String, finalValue:Object, removeWhenInactive:Boolean = true, condition:String = Property.DEFAULT ):void
		{
			var property:Property = getProperty(propertyName);
			property.finalValue = finalValue;
			property.condition = condition;
		}
		
		
		/**
		 * <p>Gets a Property and will  return the value of 
		 * it. Be careful using this function, as it returns 
		 * an object, so it doesn't know the type of your 
		 * object. That is your responsibility.
		 * 
		 * @param propertyName -- The name of the Property to get the value from.
		 * 
		 * @return -- Returns the value of the Property.
		 */
		public function getPropertyValue( propertyName:String ):Object
		{
			if( _propertyBank[propertyName] == null ) throw new IllegalOperationError("There is no Achievement Property called: " + propertyName, 003);
			return _propertyBank[propertyName].value;
		}
		
		
		/**
		 * <p>Sets the value of a Property and checks whether 
		 * the property and the achievements attached to it 
		 * are completed</p>
		 * 
		 * @param propertyName -- The name of the Property to update.
		 * @param value -- The new value of the Property.
		 */
		public function setProperty( propertyName:String, value:Object ):void
		{
			var property:Property = getProperty(propertyName);
			if( !property.isActive ) return;
			property.value = value;
			if( _changedProperties.indexOf(property) == -1 ) _changedProperties.push(property);
		}
		
		
		/**
		 * <p>Checks whether a Medal is unlocked or not 
		 * by using the Medal name that you pass in.</p>
		 * 
		 * @param medalName -- The name of the Medal to check.
		 * 
		 * @return -- Returns true/false on whether the Medal is unlocked.
		 */
		public function isUnlocked( medalName:String ):Boolean
		{
			var medal:Medal = getMedal(medalName);
			return medal.isUnlocked;
		}
		
		
		/**
		 * <p>This will check if any Medals that contain the completed 
		 * Property are completed. If all Medals are completed, then the 
		 * Property will be deleted if specified as <code>true</code> in 
		 * registerProperty.</p>
		 * 
		 * @param event -- The event passed into the handler.
		 */
		private function onPropertyComplete( event:PropertyEvent ):void
		{
			var property:Property = _propertyBank[event.target.name];
			var medalList:Dictionary = property.owners;
			
			for each( var medal:Medal in medalList )
			{
				if( medal != null )
				{
					medal.checkForCompletion();
				}
			}
			if( property.numOfOwners <= 0 )
				property.isActive = false;
			
			if( _changedProperties.indexOf(property) == -1 ) _changedProperties.push(property);
			if( !_devMode ) saveProperties(null);
		}
		
		
		/**
		 * <p>Handles what happens when a Medal is unlocked. 
		 * If <code>onUnlock</code> is set, then it will be called. 
		 * If you make a custom 'onUnlock' function, it MUST accept 
		 * a 'Medal' as a parameter.</p>
		 * 
		 * @param event -- The event passed into the handler.
		 */
		private function onMedalUnlock(event:Event):void
		{
			var medal:Medal = event.target as Medal;
			medal.removeEventListener(MedalEvent.UNLOCKED, onMedalUnlock);
			if(!_devMode) _storage.saveMedal(medal);
			if( _onUnlock != null ) _onUnlock(medal);
		}
		
		
		/**
		 * <p>The function to be called whenever an Achievement is unlocked. You 
		 * can create your own functions for this - but they must accept a Medal 
		 * as a parameter.</p>
		 * <code>function myCustomUnlock( medalUnlocked:Medal ):void</code>
		 */
		public function set onUnlock( value:Function ):void { _onUnlock = value; }
		
		
		/**
		 * <p>The function to be called whenever you wish to 
		 * be in developer mode. In developer mode, the 
		 * properties and medals will not be saved.</p>
		 */
		public function set devMode( value:Boolean ):void {_devMode = value; }
		public function get devMode():Boolean { return _devMode; }
		
		
		public function getUnlockedMedals():Array
		{
			var tempBank:Array = [];
			for each( var medal:Medal in _medalBank )
			{
				tempBank.push(medal);
			}
			return tempBank;
		}
		
		
		public function set notifier( value:IAchievementNotify ):void { _notifier = value; }
		
		
		public function set storage( value:IAchievementStorage ):void { _storage = value; }
		
		
	}
}