"""F49 pre-fold phase magnitudes; observation only, no solver behavior change."""
import math


def phase_magnitudes(rows):
    position = {p: [abs(v) for r in rows for b in r['feet']+r['other_bodies']
                    for v in b['position_delta_wu'][p]] for p in ('angular','self_contact')}
    drive = [abs(e['impulse']) for r in rows for e in r['drive_events']]
    limits = [abs(e['impulse']) for r in rows for e in r['angular_limit_events']]
    net = [abs(e['impulse']) for r in rows for e in r['angular_joints']]
    contacts = [math.hypot(e['x'],e['y']) for r in rows for e in r['self_contact_events']]
    net_self = [math.hypot(e['x'],e['y']) for r in rows for e in r['self_impulses_ns']]
    if not all(math.isfinite(v) for v in sum(position.values(),[]) + drive+limits+net+contacts+net_self):
        raise ValueError('Nonfinite raw angular/self magnitude')
    # Check observation sums; do not let a single folded hinge column hide a fight.
    for r in rows:
        for index,(joint,event) in enumerate(zip(r['angular_joints'],r['drive_events'],strict=True)):
            total = event['impulse'] + math.fsum(e['impulse'] for e in r['angular_limit_events'] if e['joint']==index)
            if abs(total-joint['impulse']) > 1e-12:
                raise ValueError('Raw angular event impulses disagree with tick net')
        for i, total in enumerate(r['self_impulses_ns']):
            for axis in ('x','y'):
                value = math.fsum((int(e['second']==i)-int(e['first']==i))*e[axis] for e in r['self_contact_events'])
                if abs(value-total[axis]) > 1e-12:
                    raise ValueError('Raw self events disagree with body net impulse')
    return {'scope':'RAW pre-fold; position is max absolute coordinate of net per-tick phase (not sum of magnitudes across iterations)',
            'angular': {'max_abs_position_delta_wu':max(position['angular'],default=0.),
                        'impulse_unit':'mass*WU^2/s',
                        'max_abs_drive_impulse':max(drive,default=0.),
                        'max_abs_limit_block_impulse':max(limits,default=0.),
                        'max_abs_impulse':max(drive+limits,default=0.),
                        'max_abs_tick_net_impulse':max(net,default=0.)},
            'self_contact': {'max_abs_position_delta_wu':max(position['self_contact'],default=0.),
                             'scale_validation': 'ZERO Slug self-contact impulses: path exercised ONLY by unit tests; scale validation requires an eligible self-hit preset with nonzero impulse' if not any(contacts) else 'nonzero events observed; not acceptance',
                             'impulse_unit':'N*s', 'max_impulse_magnitude':max(contacts,default=0.),
                             'max_body_net_impulse_magnitude':max(net_self,default=0.)}}
