package achievement.properties
{
	import flash.events.TimerEvent;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	import flash.utils.Timer;
	
	public class TimedProperty extends Property implements IExternalizable
	{
		
		protected var _timeSpan:uint;
		protected var _timer:Timer;
		protected var _lastValue:Object;
		protected var _isBusy:Boolean;
		
		
		/**
		 * The constructor for a Timed Property.
		 */
		public function TimedProperty()
		{
			_isBusy = false;
		}
		
		
		public override function checkForCompletion():void
		{
			super.checkForCompletion();
			if( _isComplete )
			{
				_timer = new Timer(_timeSpan,1);
				_timer.addEventListener(TimerEvent.TIMER, onExpired);
				_timer.start();
				_isBusy = true;
			}
		}
		
		
		protected function onExpired(event:TimerEvent):void
		{
			_currentValue = _lastValue;
			_isBusy = false;
			_timer.removeEventListener(TimerEvent.TIMER, onExpired);
			_isComplete = false;
		}
		
		
		public override function set value(val:Object):void
		{
			if( _lastValue == val )
			{
				_currentValue = val;
				return;
			}
			if( !_isBusy )
			{
				_lastValue = _currentValue;
				_currentValue = val;
				checkForCompletion();
			}
		}
		
		
		public static function create( propertyName:String, startValue:Object, finalValue:Object, timeInMillis:uint,
									   condition:String = Property.DEFAULT, removeWhenInactive:Boolean = true):TimedProperty
		{
			var property:TimedProperty = new TimedProperty();
			property.name = propertyName;
			property.timeSpan = timeInMillis;
			property.value = startValue;
			property.finalValue = finalValue;
			property.condition = condition;
			property.removeWhenInactive = removeWhenInactive;
			return property;
		}
		
		
		override public function readExternal(input:IDataInput):void
		{
			super.readExternal(input);
			_timeSpan = input.readUnsignedInt();
			_lastValue = input.readObject();
			_isBusy = input.readBoolean();
		}
		
		
		override public function writeExternal(output:IDataOutput):void
		{
			super.writeExternal(output);
			output.writeUnsignedInt(_timeSpan);
			output.writeObject(_lastValue);
			output.writeBoolean(_isBusy);
		}
		
		
		public function set timeSpan( value:uint ):void { _timeSpan = value; }
		public function get timeSpan():uint { return _timeSpan; }
		
		
	}
	
}