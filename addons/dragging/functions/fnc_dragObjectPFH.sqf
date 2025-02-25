#include "..\script_component.hpp"
/*
 * Author: commy2
 * PFH for dragging an object.
 *
 * Arguments:
 * 0: Arguments <ARRAY>
 * - 0: Unit <OBJECT>
 * - 1: Target <OBJECT>
 * - 2: Start time <NUMBER>
 * 1: PFEH Id <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * [[player, cursorTarget, CBA_missionTime], _idPFH] call ace_dragging_fnc_dragObjectPFH;
 *
 * Public: No
 */

#ifdef DEBUG_ENABLED_DRAGGING
    systemChat format ["%1 dragObjectPFH running", CBA_missionTime];
#endif

params ["_args", "_idPFH"];
_args params ["_unit", "_target", "_startTime"];

if !(_unit getVariable [QGVAR(isDragging), false]) exitWith {
    TRACE_2("drag false",_unit,_target);
    _idPFH call CBA_fnc_removePerFrameHandler;
};

// Drop if the crate is destroyed OR (target moved away from carrier (weapon disasembled))
if (!alive _target || {_unit distance _target > 10}) then {
    TRACE_2("dead/distance",_unit,_target);

    if ((_unit distance _target > 10) && {(CBA_missionTime - _startTime) < 1}) exitWith {
        // attachTo seems to have some kind of network delay and target can return an odd position during the first few frames,
        // So wait a full second to exit if out of range (this is critical as we would otherwise detach and set it's pos to weird pos)
        TRACE_3("ignoring bad distance at start",_unit distance _target,_startTime,CBA_missionTime);
    };

    [_unit, _target] call FUNC(dropObject);

    _idPFH call CBA_fnc_removePerFrameHandler;
};

// Drop static if crew is in it (UAV crew deletion may take a few frames)
if (_target isKindOf "StaticWeapon" && {(crew _target) isNotEqualTo []} && {!(_target getVariable [QGVAR(isUAV), false])}) then {
    TRACE_2("static weapon crewed",_unit,_target);

    [_unit, _target] call FUNC(dropObject);

    _unit setVariable [QGVAR(hint), nil];
    call EFUNC(interaction,hideMouseHint);

    _idPFH call CBA_fnc_removePerFrameHandler;
};
