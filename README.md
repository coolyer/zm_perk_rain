# zm_perk_rain Perks rain from the sky!
**Author:** Coolyer  
**⚠️ Please credit if used.**


---

## 📥 Installation

1. Place **zm_perk_rain.gsc** into your `usermaps/scripts/zm/` folder.  
2. In your main maps GSC add `#using scripts\zm\zm_perk_rain;`
3. add this to your zone:
```
    fx,explosions/fx_exp_grenade_default
    fx,dlc5/sumpf/fx_perk_lottery_end
    fx,dlc5/sumpf/fx_perk_lottery_front
    fx,dlc5/sumpf/fx_perk_lottery_flash
    scriptparsetree,scripts/zm/zm_perk_rain.gsc
```
4. Open **zm_perk_rain.gsc** and edit the defines if you wish to change something.
```
#define PERK_RAIN_HEIGHT           2500
#define PERK_RAIN_SLAM_TIME        0.9
#define PERK_RAIN_STAGGER          0.35
#define PERK_RAIN_SOUND_SLAM       "evt_nuke_flash" // change this to your custom perk slam sound if you have one
#define PERK_BOTTLE_HIT_SOUND      "bottles_multiple" // change this to your custom perk bottle hit sound if you have one

#define PERK_RAIN_WOBBLE_HEIGHT    40
#define PERK_RAIN_WOBBLE_TIME      1.0
#define PERK_RAIN_WOBBLE_ACCEL     0.3
#define PERK_RAIN_WOBBLE_DECEL     0.2
#define PERK_RAIN_VIBRATE_INTENSITY 1.2
#define PERK_RAIN_VIBRATE_FREQ     0.8
#define PERK_RAIN_VIBRATE_TIME     1.0

// 0 = every round all slam together & will shuffle depending on min and max || 1 = one perk per min and max rounds until all placed
#define PERK_RAIN_MODE             0
#define PERK_RAIN_INTERVAL_MIN     1
#define PERK_RAIN_INTERVAL_MAX     2

#define PERK_RAIN_LOTTERY_FX_FRONT  "dlc5/sumpf/fx_perk_lottery_front"
#define PERK_RAIN_LOTTERY_FX_END    "dlc5/sumpf/fx_perk_lottery_end"
#define PERK_RAIN_LOTTERY_FX_FLASH  "dlc5/sumpf/fx_perk_lottery_flash"
#define PERK_RAIN_LOTTERY_FX_GRENADE "explosions/fx_exp_grenade_default"
```
5. Enjoy :) 
---
Any issues please contact me on discord:
    `coolyer`