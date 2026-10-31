"""Restricted read-only Godot4 capture inspector, NOT engine/Codec evidence.
Accept only the scalar/container/packed numeric forms in saved physics captures.
Never instantiate objects, step a clock, sanitize NaN/Inf, or repair a state.
Unknown headers, object types, truncation, duplicate keys and trailing data fail.
StringName is displayed as text; typed arrays as lists. NOT a round-trip codec.
"""
import struct


def decode(data):
    if not isinstance(data, bytes) or len(data) > 2 * 1024 * 1024:
        raise ValueError('capture byte bound/type')
    pos = 0
    nodes = 0

    def take(n):
        nonlocal pos
        if n < 0 or n > len(data) - pos:
            raise ValueError('truncated capture')
        result = data[pos:pos+n]
        pos += n
        return result

    def u32():
        return struct.unpack('<I', take(4))[0]

    def count():
        n = u32()
        if n > (len(data)-pos)//4:
            raise ValueError('container count/shared form unsupported')
        return n

    def value(depth=0):
        nonlocal nodes
        nodes += 1
        if depth > 128 or nodes > 250000:
            raise ValueError('capture nesting/node bound')
        header = u32()
        kind, flags = header & 0xffff, header >> 16
        if kind in (2, 3):
            if flags not in (0, 1):
                raise ValueError('unknown numeric flags')
            fmt = ('<q' if flags else '<i') if kind == 2 else ('<d' if flags else '<f')
            return struct.unpack(fmt, take(struct.calcsize(fmt)))[0]
        if kind == 28:
            if flags == 1:
                builtin = u32()
                if builtin not in (1, 2, 3, 4, 21, 27, 28):
                    raise ValueError('unsupported typed array element')
            elif flags != 0:
                raise ValueError('object/unknown typed array')
            return [value(depth+1) for _ in range(count())]
        if flags != 0:
            raise ValueError('unknown container/scalar flags')
        if kind == 0:
            return None
        if kind == 1:
            v = u32()
            if v not in (0, 1):
                raise ValueError('invalid bool')
            return bool(v)
        if kind in (4, 21):
            n = u32()
            text = take(n).decode('utf-8')
            if any(take((-n) % 4)):
                raise ValueError('string padding')
            return text
        if kind == 27:
            result = {}
            for _ in range(count()):
                k = value(depth+1)
                if not isinstance(k, (str, int, float)) or k in result:
                    raise ValueError('unsupported/duplicate dictionary key')
                result[k] = value(depth+1)
            return result
        if kind in (29, 30, 31, 32, 33):
            fmt = {29:'B', 30:'i', 31:'q', 32:'f', 33:'d'}[kind]
            n = u32()
            size = n * struct.calcsize(fmt)
            result = list(struct.unpack('<'+str(n)+fmt, take(size)))
            if any(take((-size) % 4)):
                raise ValueError('packed padding')
            return result
        raise ValueError('unsupported variant type: '+str(kind))

    result = value()
    if pos != len(data):
        raise ValueError('trailing capture bytes')
    return result
