import com.GameInterface.Game.Character;
import com.GameInterface.Inventory;
import com.GameInterface.InventoryItem;
import com.GameInterface.Resource;
import com.Utils.ID32;

import caurina.transitions.Tweener;

import descendent.hud.reticle.Color;
import descendent.hud.reticle.DefaultArcBarMeter;
import descendent.hud.reticle.Gauge;
import descendent.hud.reticle.IMeter;

class descendent.hud.reticle.PowerGauge extends Gauge
{
	private static var POWER_MAX:Number = 5;

	private var _r:Number;

	private var _angle_a:Number;

	private var _angle_b:Number;

	private var _thickness:Number;

	private var _equip:Number;

	private var _character:ID32;
	
	private var _subject:Character;
	
	private var _is_distant:Boolean;

	private var _inventory:Inventory;

	private var _power:Number;

	private var _meter:IMeter;

	public function PowerGauge(r:Number, angle_a:Number, angle_b:Number, thickness:Number,
		equip:Number)
	{
		super();

		this._r = r;
		this._angle_a = angle_a;
		this._angle_b = angle_b;
		this._thickness = thickness;
		this._equip = equip;

		this._power = 0;
	}

	private function setGauge(value:Number):Void
	{
		Tweener.addTween(this._meter, {
			setMeter: value,
			time: 0.3,
			transition: "linear",
			onComplete: this.meter_onMeter,
			onCompleteParams: [value],
			onCompleteScope: this
		});
	}
	
	public function setSubject(value:Character):Void
	{
		this.discard_subject();
		this.prepare_subject(value);
		this.discard_meter();
		this.prepare_meter();
		this.refresh_power();
	}
	
		
	public function set_unactive_distant(){
		if (!this._is_distant)
			return;
			
		this.setAlpha(30);
	}
	
	public function set_active_distant(){
		if (!this._is_distant)
			return;
			
		this.setAlpha(100);
	}

	public function prepare(o:MovieClip):Void
	{
		super.prepare(o);

		this._character = Character.GetClientCharID();
		this._inventory = new Inventory(new ID32(_global.Enums.InvType.e_Type_GC_WeaponContainer, this._character.GetInstance()));
		

		this.prepare_meter();
		this.prepare_subject();
		
		this.refresh_power();

		this._inventory.SignalItemLoaded.Connect(this.inventory_onPlant, this);
		this._inventory.SignalItemAdded.Connect(this.inventory_onPlant, this);
		this._inventory.SignalItemChanged.Connect(this.inventory_onTransform, this);
		this._inventory.SignalItemRemoved.Connect(this.inventory_onPluck, this);

		Resource.SignalResourceChanged.Connect(this.character_onPower, this);
	}
	
	

	private function prepare_meter():Void
	{
		var thing:InventoryItem = this._inventory.GetItemAt(this._equip);
		var barColor:Number   = 0xFFFFFF;
		var shaftColor:Number = 0xFFFFFF;
		var powerType:Number  = -1;
		var is_distant:Boolean = false;

		if (thing == null)
			return;
			
		

		if ((thing.m_Type & _global.Enums.WeaponTypeFlag.e_WeaponType_AssaultRifle) != 0)
		{
			barColor = 0x10B9D6;
			powerType = _global.Enums.ResourceType.e_ClipResourceType;
			is_distant = true;
		}
		else if ((thing.m_Type & _global.Enums.WeaponTypeFlag.e_WeaponType_Sword) != 0)
		{
			barColor = 0x7688ED ;
			powerType = _global.Enums.ResourceType.e_CutResourceType;
		}
		else if ((thing.m_Type & _global.Enums.WeaponTypeFlag.e_WeaponType_Death) != 0)
		{
			//barColor = 0xFF5857;
			barColor = 0x31c3e0;
			powerType = _global.Enums.ResourceType.e_BloodResourceType;
		}
		else if ((thing.m_Type & _global.Enums.WeaponTypeFlag.e_WeaponType_Jinx) != 0)
		{
			barColor = 0xD188F7;
			powerType = _global.Enums.ResourceType.e_ChaosResourceType;
		}
		else if ((thing.m_Type & _global.Enums.WeaponTypeFlag.e_WeaponType_Handgun) != 0)
		{
			barColor = 0xFFC13D;
			powerType = _global.Enums.ResourceType.e_BulletResourceType;
			is_distant = true;
		}
		else if ((thing.m_Type & _global.Enums.WeaponTypeFlag.e_WeaponType_Fire) != 0)
		{
			//barColor = 0xF4802B;
			barColor = 0x32d0f0;
			powerType = _global.Enums.ResourceType.e_ElementalResourceType;
		}
		else if ((thing.m_Type & _global.Enums.WeaponTypeFlag.e_WeaponType_Fist) != 0)
		{
			barColor = 0xEC474B;
			powerType = _global.Enums.ResourceType.e_StrikeResourceType;
		}
		else if ((thing.m_Type & _global.Enums.WeaponTypeFlag.e_WeaponType_Club) != 0)
		{
			barColor = 0xFF8042;
			powerType = _global.Enums.ResourceType.e_SlamResourceType;
		}
		else if ((thing.m_Type & _global.Enums.WeaponTypeFlag.e_WeaponType_Shotgun) != 0)
		{
			barColor = 0xFFB12E;
			powerType = _global.Enums.ResourceType.e_ShellResourceType;
			is_distant = true;
		}
		this.prepare_meter_process(new Color(barColor, 33), new Color(barColor, 100), new Color(shaftColor, 100), powerType, is_distant);
	
	}

	private function prepare_meter_process(color_shaft:Color, color_meter:Color, color_notch:Color,
		power:Number, is_distant:Boolean):Void
	{
		var notch:/*Number*/Array = [1, 2, 3, 4];

		this._meter = new DefaultArcBarMeter(this._r, this._angle_a, this._angle_b, this._thickness,
			color_shaft, color_meter, color_notch, PowerGauge.POWER_MAX, false);
		this._meter.setNotch(notch);
		this._meter.prepare(this.content);

		this._power = power;
		this._is_distant = is_distant;
	}
	
	private function prepare_subject(subject:Character):Void
	{
		if (subject == null)
			return;

		var which:ID32 = subject.GetID();

		if ((which.GetType() != _global.Enums.TypeID.e_Type_GC_Character)
			&& (which.GetType() != _global.Enums.TypeID.e_Type_GC_Destructible))
		{
			return;
		}

		this._subject = subject;
		
		if (this._is_distant){
			this._character = this._subject.GetID();
		}
		
		this._subject.SignalStatChanged.Connect(this.subject_onValue, this);
	}
	
	private function refresh_power():Void 
	{
		this.setGauge(Resource.GetResourceAmount(this._power, this._character));
	}
	
	private function refresh_subject():Void
	{
		var subject:Character = this._subject;

		this.discard_subject();
		this.prepare_subject(subject);
	}

	public function discard():Void
	{
		Resource.SignalResourceChanged.Disconnect(this.character_onPower, this);

		this._inventory.SignalItemLoaded.Disconnect(this.inventory_onPlant, this);
		this._inventory.SignalItemAdded.Disconnect(this.inventory_onPlant, this);
		this._inventory.SignalItemChanged.Disconnect(this.inventory_onTransform, this);
		this._inventory.SignalItemRemoved.Disconnect(this.inventory_onPluck, this);

		this.discard_meter();
		this.discard_subject();

		super.discard();
	}

	private function discard_meter():Void
	{
		if (this._meter == null)
			return;

		this._power = 0;

		Tweener.removeTweens(this._meter);

		this._meter.discard();
		this._meter = null;

		this.sleep();
	}
	
	private function discard_subject():Void
	{
		if (this._subject == null)
			return;

		this._subject.SignalStatChanged.Disconnect(this.subject_onValue, this);

		this._subject = null;
		
		Tweener.removeTweens(this, "setPending");
		
		if (this._is_distant){
			
			this._power = 0;
			
		}
		
	}
	
	private function subject_onValue(which:Number):Void
	{
		if (which == _global.Enums.Stat.e_PlayerFaction)
			this.refresh_subject();
		else if (which == _global.Enums.Stat.e_Side)
			this.refresh_subject();
		else if (which == _global.Enums.Stat.e_CarsGroup)
			this.refresh_subject();
	}

	private function inventory_onPlant(inventory:ID32, which:Number):Void
	{
		if (which != this._equip)
			return;

		this.discard_meter();
		this.prepare_meter();
	}

	private function inventory_onTransform(inventory:ID32, which:Number):Void
	{
		if (which != this._equip)
			return;

		this.discard_meter();
		this.prepare_meter();
	}

	private function inventory_onPluck(inventory:ID32, which:Number, replant:Boolean):Void
	{
		if (which != this._equip)
			return;

		this.discard_meter();
	}

	private function character_onPower(which:Number, value:Number, character:ID32):Void
	{
		if (which == 0)
			return;

		if (which != this._power)
			return;

		if (!character.Equal(this._character) && !this._is_distant)
			return;
			
		if (!character.Equal(this._subject.GetID()) && this._is_distant)
			return;

		this.setGauge(value);
	}

	private function meter_onMeter(value:Number):Void
	{
		if (value >= PowerGauge.POWER_MAX)
			this.sleep();
		else
			this.rouse();
	}
}
