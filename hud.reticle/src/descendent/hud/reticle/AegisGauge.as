import com.GameInterface.Game.Character;
import com.Utils.Colors;
import com.Utils.ID32;

import caurina.transitions.Tweener;

import descendent.hud.reticle.Color;
import descendent.hud.reticle.Gauge;
import descendent.hud.reticle.IMeter;
import descendent.hud.reticle.DefaultArcBarMeter;

import com.GameInterface.Log;

class descendent.hud.reticle.AegisGauge extends Gauge
{
	private var _r:Number;

	private var _angle_a:Number;

	private var _angle_b:Number;

	private var _thickness:Number;

	private var _subject:Character;
	
	private var _current:IMeter;

	private var _pending:IMeter;
	
	private var _shaft:IMeter;

	private var _value_maximum:Number;

	private var _value_current:Number;

	private var _value_pending:Number;
	
	private var _color:Number;
	
	private var _hex_color:Number;
	
	private var _stat_id:Number ;
	
	private var _max_stat_id:Number ;

	public function AegisGauge(r:Number, angle_a:Number, angle_b:Number, thickness:Number, color:Number)
	{
		super();

		this._r = r;
		this._angle_a = angle_a;
		this._angle_b = angle_b;
		this._thickness = thickness;
		this._color = color;
	}

	public function setSubject(value:Character):Void
	{
		this.discard_subject();
		this.prepare_subject(value);
	}

	public function prepare(o:MovieClip):Void
	{
		super.prepare(o);
		
		switch(this._color){
			case 1: // 'pink' 
				this._hex_color = 0xD900C3;
				this._stat_id = _global.Enums.Stat.e_CurrentPinkShield;
				this._max_stat_id = _global.Enums.Stat.e_PercentPinkShield;
				break;
			case 2: // 'blue'
				this._hex_color = 0x11DEF5;
				this._stat_id = _global.Enums.Stat.e_CurrentBlueShield;
				this._max_stat_id = _global.Enums.Stat.e_PercentBlueShield;
				break;
			case 3: // 'red'
				this._hex_color = 0xD90404;
				this._stat_id = _global.Enums.Stat.e_CurrentRedShield;
				this._max_stat_id = _global.Enums.Stat.e_PercentRedShield;
				break;
			default:
				this._hex_color = 0xF7F30F;
				
		}
		
		
		this.prepare_shaft();
		this.prepare_meter();

		this._current.dismiss();
		this._pending.dismiss();
		this._shaft.dismiss();
	}

	private function prepare_shaft():Void
	{
		var notch:/*Number*/Array = [0.25, 0.5, 0.75];

		this._shaft = new DefaultArcBarMeter(this._r, this._angle_a, this._angle_b, this._thickness,
			new Color(this._hex_color, 33), new Color(this._hex_color, 100), new Color(0xFFFFFF, 100), 1.0, false);
		//this._shaft.setNotch(notch);
		this._shaft.prepare(this.content);
	}


	private function prepare_meter():Void
	{
		this.prepare_pending();
		this.prepare_current();
	}

	private function prepare_current():Void
	{
		this._current = new DefaultArcBarMeter(this._r, this._angle_a, this._angle_b, this._thickness,
			null, new Color(this._hex_color, 100), new Color(0xFFFFFF, 100), 1.0, false);
		this._current.prepare(this.content);
	}

	private function prepare_pending():Void
	{
		this._pending = new DefaultArcBarMeter(this._r, this._angle_a, this._angle_b, this._thickness,
			null, new Color(Colors.e_ColorHealthCritical, 100), new Color(0xFFFFFF, 100), 1.0, false);
			//TODO Check that red here is not disgusting with ANY aegis shield color
		this._pending.prepare(this.content);
	}

	/*private function prepare_notch():Void
	{
		var notch:Array = [0.25, 0.5, 0.75];

		this._notch = new DefaultArcBarMeter(this._r, this._angle_a, this._angle_b, this._thickness,
			null, new Color(0x000000, 0), new Color(0xFFFFFF, 100), 1.0, false);
		this._notch.setNotch(notch);
		this._notch.prepare(this.content);
	}*/

	private function prepare_subject(subject:Character):Void
	{
		this._current.dismiss();
		this._pending.dismiss();
		this._shaft.dismiss();
		
		if (subject == null)
			return;

		var which:ID32 = subject.GetID();

		if ((which.GetType() != _global.Enums.TypeID.e_Type_GC_Character)
			&& (which.GetType() != _global.Enums.TypeID.e_Type_GC_Destructible))
		{
			return;
		}

		this._subject = subject;
		
		this._value_maximum = 0;
		this._value_current = 0;
		this._value_pending = 0;	

		if (subject.IsEnemy())
		{
			var life:Number = this._subject.GetStat(_global.Enums.Stat.e_Life, 2);
		
			this._value_maximum = Math.round(this._subject.GetStat(this._max_stat_id, 2) * life);
			this._value_current = this._subject.GetStat(this._stat_id, 2);
			this._value_pending = this._value_current;
		}
		else if (subject.IsClientChar())
		{
			// Check the color of the aegis shield
			if (this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldType, 2) == this._color){
				this._value_maximum = this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldStrengthMax, 2);
				this._value_current = this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldStrength, 2);
				this._value_pending = this._value_current;
			} 
		}
		else
		{
			trace("OMG WTF BBQ : AegisGauge.as line 159");
		}
		
		this._subject.SignalStatChanged.Connect(this.subject_onValue, this);

		if (this._value_maximum == 0)
			return;

		this._current.present();
		this._shaft.present();
		//this._notch.present();

		this.refresh_meter();
	}


	private function refresh_maximum():Void
	{
		var old:Number = this._value_maximum;
		
		var value:Number = 0;
		
		if (this._subject.IsEnemy())
		{
			value = Math.round(this._subject.GetStat(this._max_stat_id, 2) * this._subject.GetStat(_global.Enums.Stat.e_Life, 2));
		}
		else if (this._subject.IsClientChar() && this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldType, 2) == this._color)
		{
			value = this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldStrengthMax, 2);
		}
		else
		{
			trace("OMG WTF BBQ : AegisGauge.as line 218");
		}
		
		if (old == 0 && value != 0){
			this._current.present();
			this._shaft.present();
			this.refresh_meter();
		}
		

		this.setMaximum(value);
	}

	private function getMaximum():Number
	{
		return this._value_maximum;
	}

	private function setMaximum(value:Number):Void
	{
		this._value_maximum = value;

		this.refresh_meter();
	}

	private function refresh_current():Void
	{
		var value:Number = 0;

		if (this._subject.IsEnemy())
		{
			value = this._subject.GetStat(this._stat_id, 2);
		}
		else if (this._subject.IsClientChar() && this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldType, 2) == this._color)
		{
			value = this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldStrength, 2);
		}
		
		this.setCurrent(value);

		var timer:Number = (value >= this._value_pending)
			? 0.0
			: 0.3;

		Tweener.addTween(this, {
			setPending: value,
			time: timer,
			transition: "linear"
		});
	}

	private function getCurrent():Number
	{
		return this._value_current;
	}

	private function setCurrent(value:Number):Void
	{
		this._value_current = value;

		this.refresh_meter();
	}

	private function getPending():Number
	{
		return this._value_pending;
	}

	private function setPending(value:Number):Void
	{
		this._value_pending = value;

		this.refresh_meter();
	}


	private function refresh_meter():Void
	{

		if (this._value_pending <= this._value_current)
			this._pending.dismiss();
		else
			this._pending.present();

        this._current.setMeter(this._value_current / this._value_maximum);
        this._pending.setMeter(this._value_pending / this._value_maximum);
        //this._notch.setMeter(1);

		this.refresh_awake();
	}

	private function refresh_awake():Void
	{
		if (this._subject.IsDead())
			this.sleep();
		else if (this._subject.IsGhosting())
			this.sleep();
		//else if (this._value_current >= this._value_maximum)
		//	this.sleep();
		else
			this.rouse();
	}

	private function refresh_subject():Void
	{
		var subject:Character = this._subject;

		this.discard_subject();
		this.prepare_subject(subject);
	}

	public function discard():Void
	{
		Tweener.removeTweens(this);
		
		this.discard_subject();
		//this.discard_notch();
		this.discard_meter();
		this.discard_shaft();

		super.discard();
	}

	private function discard_shaft():Void
	{
		if (this._shaft == null)
			return;

		this._shaft.discard();
		this._shaft = null;
	}


	private function discard_meter():Void
	{
		this.discard_meter_current();
		this.discard_meter_pending();

		this.sleep();
	}

	private function discard_meter_current():Void
	{
		if (this._current == null)
			return;

		this._current.discard();
		this._current = null;
	}

	private function discard_meter_pending():Void
	{
		if (this._pending == null)
			return;

		this._pending.discard();
		this._pending = null;
	}

	/*private function discard_notch():Void
	{
		if (this._notch == null)
			return;

		this._notch.discard();
		this._notch = null;
	}*/

	private function discard_subject():Void
	{
		if (this._subject == null)
			return;

		this._subject.SignalStatChanged.Disconnect(this.subject_onValue, this);

		this._subject = null;

		Tweener.removeTweens(this, "setPending");

		this._current.dismiss();
		this._pending.dismiss();
		this._shaft.dismiss();
		//this._notch.dismiss();

		this._value_maximum = 0;
		this._value_current = 0;
		this._value_pending = 0;

		this.sleep();
	}

	private function subject_onValue(which:Number):Void
	{
		switch(which){
			
			case _global.Enums.Stat.e_PlayerAegisShieldStrength:
			case this._stat_id:
				this.refresh_current();
				
			case _global.Enums.Stat.e_PlayerAegisShieldStrengthMax:
			case _global.Enums.Stat.e_Life:
			case this._max_stat_id:
				this.refresh_maximum();
				break;
				
			case _global.Enums.Stat.e_PlayerAegisShieldType:
			case _global.Enums.Stat.e_PlayerFaction:
			case _global.Enums.Stat.e_Side:
			case _global.Enums.Stat.e_CarsGroup:
				this.refresh_subject();
				break;
				
		}
		
		/*if (this._color == 3){
			var log:String = "";
			switch(which){
				case _global.Enums.Stat.e_PlayerAegisShieldStrengthMax:
					log = "Max shield update to " + this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldStrengthMax, 2);
					break;
				case _global.Enums.Stat.e_PlayerAegisShieldStrength:
					log = "Current shield update to " + this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldStrength, 2);
					break;
				case _global.Enums.Stat.e_PlayerAegisShieldType:
					log = "Current shield type update to " + this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldType, 2);
					
				default:
					return;
			}
			
			log += ", ";
			
			switch(this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldType, 2)){
				case 3:
					log += "for me";
					break;
				default: 
					log += "not for me";
					
			}
			
			log += "\t |||| current stats (CUR/MAX) : (" + this._value_current + "/" + this._value_maximum + ") / (" + this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldStrength, 2) + "/" + this._subject.GetStat(_global.Enums.Stat.e_PlayerAegisShieldStrengthMax, 2) + ") ";
			
			Log.Error("AegisGauge |||| ", log);
		}*/
		
	}
}
