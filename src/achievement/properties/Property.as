package achievement.properties
{
	import achievement.core.Medal;
	import achievement.events.PropertyEvent;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	
	
	/**
	 * <p>The Property is for use with an Medal. It describes 
	 * the conditions for an Medal to be completed. For example - 
	 * an Medal that was given for collecting 5 coins would be 
	 * likely have a property you may call 'coinsCollected' which 
	 * would have a <code>finalValue</code> of 5.</p>
	 */
	public class Property extends EventDispatcher implements IExternalizable
	{
		
		private var _name:String;
		protected var _isComplete:Boolean;
		protected var _finalValue:Object;
		protected var _currentValue:Object;
		protected var _conditionComparison:String;
		protected var _condition:String;
		protected var _owners:Dictionary;
		protected var _numOwners:uint;
		protected var _removeWhenInactive:Boolean;
		protected var _active:Boolean = true;
		
		
		// List of Preset Conditions for the currentValue against the finalValue.
		public static const DEFAULT:String = "default";
		public static const EQUAL_TO:String = "equalTo";
		public static const GREATER_THAN:String = "greaterThan";
		public static const LESS_THAN:String = "lessThan";
		public static const EQUAL_TO_OR_GREATER_THAN:String = "equalToOrGreaterThan";
		public static const EQUAL_TO_OR_LESS_THAN:String = "equalToOrLessThan";
		public static const DEFAULT_COMPARISON_FUNCTION:String = "defaultCompare";
		
		
		/**
		 * The constructor for a Property.
		 * 
		 * @param name -- The name/identifier of the Property.
		 * @param startValue -- The initial value of the Property.
		 * @param finalValue -- The value required for the property to be complete.
		 * @param condition -- (Default = Equal to / Greater than) The condition to test against.
		 */
		public function Property()
		{
			_owners = new Dictionary(true);
			_removeWhenInactive = true;
			_conditionComparison = DEFAULT_COMPARISON_FUNCTION;
		}
		
		
		/**
		 * <p>This function checks if the Property is completed by 
		 * doing the default calculations which are determined by 
		 * <code>condition</code>. You can make your own comparison 
		 * functions but they must follow the same format.</p>
		 * 
		 * @return -- A Boolean is returned to show whether the Property is complete.
		 * 
		 * @see conditionComparisionFunction
		 */
		protected static function defaultCompare(currentValue:Object, finalValue:Object, condition:String):Boolean
		{
			switch( condition )
			{
				case EQUAL_TO: 
					if( currentValue == finalValue ) return true; 
					break;
				case GREATER_THAN: 
					if( currentValue > finalValue ) return true; 
					break;
				case LESS_THAN: 
					if( currentValue < finalValue ) return true; 
					break;
				case EQUAL_TO_OR_GREATER_THAN: 
					if( currentValue == finalValue || currentValue > finalValue ) return true;
					break;
				case EQUAL_TO_OR_LESS_THAN: 
					if( currentValue == finalValue || currentValue < finalValue ) return true;
					break;
			}
			return false;
		}
		
		
		/**
		 * Checks to see if the property is completed.
		 */
		public function checkForCompletion():void
		{
			_isComplete = Property[_conditionComparison](_currentValue, _finalValue, _condition);
			if( _isComplete ) 
			{
				dispatchEvent( new PropertyEvent(PropertyEvent.COMPLETE) );
			}
		}
		
		
		public function addOwner(medal:Medal):void
		{
			if( _owners[medal.name] ) return;
			_owners[medal.name] = medal;
			_numOwners ++;
		}
		
		
		public function removeOwner(medal:Medal):void
		{
			if( !_owners[medal.name] ) return;
			_owners[medal.name] = null;
			_numOwners --;
		}
		
		
		public static function create( propertyName:String, startValue:Object, finalValue:Object,
									   condition:String = Property.DEFAULT, removeWhenInactive:Boolean = true):Property
		{
			var property:Property = new Property();
			property.name = propertyName;
			property.value = startValue;
			property.finalValue = finalValue;
			property.condition = condition;
			property.removeWhenInactive = removeWhenInactive;
			return property;
		}
		
		
		public function readExternal(input:IDataInput):void
		{
			_name = input.readUTF();
			_isComplete = input.readBoolean();
			_currentValue = input.readObject();
			_finalValue = input.readObject();
			_conditionComparison = input.readUTF();
			_condition = input.readUTF();
			_owners = input.readObject();
			_numOwners = input.readUnsignedInt();
			_removeWhenInactive = input.readBoolean();
			_active = input.readBoolean();
		}
		
		
		public function writeExternal(output:IDataOutput):void
		{
			output.writeUTF(_name);
			output.writeBoolean(_isComplete);
			output.writeObject(_currentValue);
			output.writeObject(_finalValue);
			output.writeUTF(_conditionComparison);
			output.writeUTF(_condition);
			output.writeObject(_owners);
			output.writeUnsignedInt(_numOwners);
			output.writeBoolean(_removeWhenInactive);
			output.writeBoolean(_active);
		}
		
		
		public function get name():String { return _name; }
		public function set name( value:String ):void { _name = value; }
		public function set conditionComparisonFunction( value:String ):void
		{
			_conditionComparison = value;
		}
		public function set condition( value:String ):void
		{
			if( value == DEFAULT )
			{
				if( typeof(value) != "number" )
				{
					_condition = EQUAL_TO_OR_GREATER_THAN;
				}
				else
				{
					_condition = EQUAL_TO;
				}
			}
			else
			{
				_condition = value;
			}
		}
		public function set value( val:Object ):void 
		{ 
			if( _currentValue == val ) return;
			_currentValue = val;
			checkForCompletion();
		}
		public function get value():Object { return _currentValue; }
		public function get finalValue():Object { return _finalValue; }
		public function set finalValue( value:Object ):void { _finalValue = value; }
		public function get condition():String { return _condition; }
		public function get owners():Dictionary { return _owners; }
		public function get isComplete():Boolean { return _isComplete; }
		public function get numOfOwners():uint { return _numOwners; }
		public function set removeWhenInactive( value:Boolean ):void { _removeWhenInactive = value; }
		public function get removeWhenInactive():Boolean { return _removeWhenInactive; }
		public function get isActive():Boolean { return _active; }
		public function set isActive( value:Boolean ):void { _active = value; }
		
	}
	
}