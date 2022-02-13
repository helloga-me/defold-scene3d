local M = {}

--
-- Quaternions
--

--- Returns the Euler angle representation of a rotation, in degrees - X.
-- @param q The quaternion in question.
-- @return A new angle.
function M.euler_x(q)
    local t = q.x * q.y + q.z * q.w
    if t > 0.4999 then
        return 0
    elseif t < -0.4999 then
        return 0
    else
        local sqx = q.x * q.x
        local sqz = q.z * q.z
        return math.atan2(2 * q.x * q.w - 2 * q.y * q.z, 1 - 2 * sqx - 2 * sqz) * 57.295779513
    end
end

--- Returns the Euler angle representation of a rotation, in degrees - Y.
-- @param q The quaternion in question.
-- @return A new angle.
function M.euler_y(q)
    local t = q.x * q.y + q.z * q.w
    if t > 0.4999 then
        return 2 * math.atan2(q.x, q.w)
    elseif t < -0.4999 then
        return -2 * math.atan2(q.x, q.w)
    else
        local sqy = q.y * q.y
        local sqz = q.z * q.z
        return math.atan2(2 * q.y * q.w - 2 * q.x * q.z, 1 - 2 * sqy - 2 * sqz) * 57.295779513
    end
end

--- Returns the Euler angle representation of a rotation, in degrees - Z.
-- @param q The quaternion in question.
-- @return A new angle.
function M.euler_z(q)
    local t = q.x * q.y + q.z * q.w
    if t > 0.4999 then
        return 90
    elseif t < -0.4999 then
        return -90
    else
        return math.asin(2 * t) * 57.295779513
    end
end

--- Returns the inverse of rotation.
-- https://docs.unity3d.com/ScriptReference/Transform.InverseTransformDirection.html
-- https://forum.unity.com/threads/what-is-the-match-behind-transform-inversetransformdirection-vector3.860068/
-- @param q The quaternion in question.
-- @return A new quaternion.
function M.quat_inv(q)
    local q2 = vmath.quat()
    local num2 = (((q.x * q.x) + (q.y * q.y)) + (q.z * q.z)) + (q.w * q.w)
    local num = 1 / num2
    q2.x = -q.x * num
    q2.y = -q.y * num
    q2.z = -q.z * num
    q2.w = q.w * num
    return q2
end

--- Creates a rotation with the specified forward and upwards directions.
-- The output is undefined for parallel vectors.
-- @param forward The forward direction to look toward.
-- @param upwards The direction to treat as up (optional, "+Y" is default).
-- @return A new quaternion.
function M.quat_look_rotation(forward, upwards)
    return scene3d.quat_look_rotation(forward, upwards)
end

--
-- Miscellaneous
--

--- Returns the sign of x.
function M.sign(x)
    return x < 0 and -1 or 1
end

--- Clamps the given value between the given minimum float and maximum float values.
-- @param value The floating point value to restrict inside the range defined by the min and max values.
-- @param min The minimum floating point value to compare against.
-- @param max The maximum floating point value to compare against.
-- @return The float result between the min and max values.
function M.clamp(value, min, max)
    if value < min then
        value = min
    elseif value > max then
        value = max
    end
    return value
end

--- Loops the value t, so that it is never larger than length and never smaller than 0.
function M.repeat_(t, length)
    return M.clamp(t - math.floor(t / length) * length, 0.0, length)
end

--- Clamps value between 0 and 1 and returns value.
function M.clamp01(value)
    if value < 0 then
        return 0
    elseif value > 1 then
        return 1
    else
        return value
    end
end

function M.limited_lerp(t, a, b, max_step)
    if scene3d.is_vector3(a) then
        return vmath.vector3(
            M.limited_lerp(t, a.x, b.x, max_step), 
            M.limited_lerp(t, a.y, b.y, max_step), 
            M.limited_lerp(t, a.z, b.z, max_step))
    elseif scene3d.is_vector4(a) then
        return vmath.vector4(
            M.limited_lerp(t, a.x, b.x, max_step), 
            M.limited_lerp(t, a.y, b.y, max_step), 
            M.limited_lerp(t, a.z, b.z, max_step), 
            M.limited_lerp(t, a.w, b.w, max_step))
    end

    local v = (b - a) * M.clamp01(t)
    if v < 0 then
        return a + math.max(v, -max_step)
    else
        return a + math.min(v, max_step)
    end
end

--- Same as "vmath.lerp" but makes sure the values interpolate correctly when they wrap around 360 degrees.
-- @param t The value is clamped to the range [0, 1].
-- @param a Degrees.
-- @param b Degrees.
-- @return An interpolated value.
function M.lerp_angle(t, a, b)
    local delta = M.repeat_((b - a), 360)
    if delta > 180 then
        delta = delta - 360
    end
    return a + delta * M.clamp01(t)
end

--- Calculates the lerp parameter between of two values.
-- @param a Start value.
-- @param b End value.
-- @param value Value between start and end.
-- @return A percentage of value between start and end.
function M.inverse_lerp(a, b, value)
    if a ~= b then
        return M.clamp01((value - a) / (b - a))
    else
        return 0.0
    end
end

--- Pingpongs the value t, so that it is never larger than length and never smaller than 0.
function M.ping_pong(t, length)
    t = M.repeat_(t, length * 2)
    return length - math.abs(t - length)
end

--- Interpolates between min and max with smoothing at the limits.
function M.smooth_step(x, min, max)
    if type(x) == "userdata" then
        return vmath.vector3(M.smooth_step(x.x, min, max), M.smooth_step(x.y, min, max), M.smooth_step(x.z, min, max))
    end
    x = M.clamp(x, min, max)
    local v1 = (x - min) / (max - min)
    local v2 = (x - min) / (max - min)
    return -2 * v1 * v1 * v1 + 3 * v2 * v2
end

return M