package achievement.core
{
	import achievement.events.MedalEvent;
	import achievement.properties.Property;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	
	
	public class Medal extends EventDispatcher implements IExternalizable
	{
		
		private var _name:String;
		private var _description:String;
		private var _properties:Dictionary;
		private var _numProperties:uint;
		private var _pointsValue:uint;
		private var _hidden:Boolean;
		private var _unlocked:Boolean;
		private var _isActive:Boolean;
		
		
		/**
		 * Constructor for the Medal Class.
		 * 
		 * @param name -- The name/identifier of the Medal.
		 * @param description -- The description of the Medal.
		 * @param pointsValue -- (Default = 0) The number of points the Medal is worth. 
		 * @param hidden -- (Default = false) Whether the Medal is hidden from the User.
		*/
		public function Medal()
		{
			_properties = new Dictionary();
			_unlocked = false;
			_numProperties = 0;
		}
		
		
		/**
		 * <p>Adds a property to the Medal. This and 
		 * any other properties must be complete for this 
		 * Medal to be unlocked.</p>
		 * 
		 * @param property -- The property to assign.
		 */
		public function assignProperty( property:Property ):void
		{
			if( _properties[property.name] ) return;
			_numProperties ++;
			_properties[property.name] = property;
		}
		
		
		/**
		 * <p>Checks whether all the Properties in the Medal 
		 * are completed. If they are, the Medal will be unlocked.</p>
		 */
		public function checkForCompletion():void
		{
			var completeProperties:int = 0;
			for each( var property:Property in _properties )
			{
				if( property.isComplete ) completeProperties++;
			}
			if( completeProperties == _numProperties )
			{
				unlockMedal();
			}
		}
		
		
		/**
		 * <p>Unlocks the Medal and dispatches the event.</p>
		 */
		public function unlockMedal():void
		{
			if( _isActive )
			{
				_isActive = false;
				_unlocked = true;
				dispatchEvent(new MedalEvent(MedalEvent.UNLOCKED));
			
				for each( var property:Property in _properties )
				{
					property.removeOwner(this);
				}
				_properties = new Dictionary();
			
				if( _hidden ) _hidden = false;
			}
		}
		
		
		/**
		 * <p>Creates the Medal internally, so that 
		 * the Medal can be serialized. Otherwise, 
		 * the Medal would have constructor parameters 
		 * which I don't think is allowed.</p>
		 * 
		 * @param medalName -- The name of the Medal
		 * @param medalDescription -- The description of the Medal
		 * @param pointsValue -- The number of Points the Medal is worth
		 * @param hidden -- Is the Medal hidden/secret to the User?
		 */
		public static function create( medalName:String, medalDescription:String, pointsValue:uint = 0, hidden:Boolean = false ):Medal
		{
			var medal:Medal = new Medal();
			medal.name = medalName;
			medal.description = medalDescription;
			medal.pointsValue = pointsValue;
			medal.isHidden = hidden;
			medal.isActive = true;
			return medal;
		}
		
		
		public function readExternal(input:IDataInput):void
		{
			_name = input.readUTF();
			_description = input.readUTF();
			_properties = input.readObject();
			_numProperties = input.readUnsignedInt();
			_pointsValue = input.readUnsignedInt();
			_hidden = input.readBoolean();
			_unlocked = input.readBoolean();
			_isActive = input.readBoolean();
		}
		
		
		public function writeExternal(output:IDataOutput):void
		{
			output.writeUTF(_name);
			output.writeUTF(_description);
			output.writeObject(_properties);
			output.writeUnsignedInt(_numProperties);
			output.writeUnsignedInt(_pointsValue);
			output.writeBoolean(_hidden);
			output.writeBoolean(_unlocked);
			output.writeBoolean(_isActive);
		}
		
		
		public function get name():String { return _name; }
		public function set name( value:String ):void { _name = value; }
		public function set description( value:String ):void { _description = value; }
		public function get description():String { return _description; }
		public function get isHidden():Boolean { return _hidden; }
		public function set isHidden( value:Boolean ):void { _hidden = value; }
		public function get properties():Dictionary { return _properties; }
		public function get numProperties():uint { return _numProperties; }
		public function set pointsValue(value:uint):void { _pointsValue = value; }
		public function get pointsValue():uint { return _pointsValue; }
		public function get isUnlocked():Boolean{ return _unlocked; }
		public function set isActive( value:Boolean ):void { _isActive = value; }
		
	}
	
}