"""End-to-end checks against the local demo. No dependencies or external calls.

Run: python scripts/demo_smoke.py [http://localhost:8080]
Creates test orders, then refunds one and completes the other.
"""
import json
import sys
import urllib.error
import urllib.request

base = (sys.argv[1] if len(sys.argv) > 1 else 'http://localhost:8080').rstrip('/')
checks = 0


def check(condition, label):
    global checks
    assert condition, label
    checks += 1
    print('PASS:', label)


def call(path, body=None, token=None, method=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(base + '/api' + path,
        data=json.dumps(body).encode() if body is not None else None,
        headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as res:
            return res.status, json.loads(res.read())
    except urllib.error.HTTPError as err:
        return err.code, json.loads(err.read())


def session(role):
    code, data = call('/demo/session', {'role': role})
    check(code == 200 and data['user']['role'] == role, role + ' demo login')
    return data


def main():
    code, status = call('/demo/status')
    check(code == 200 and status['mode'] == 'demo', 'demo services available')
    check(len(status['services']) == 6, 'six local/simulated services')
    user = session('user')
    token = user['access_token']
    partner = session('partner')['access_token']
    _, state = call('/demo/state', token=token)
    check(len(state['products']) >= 10 and len(state['points']) >= 5, 'catalog populated')
    products = [p for p in state['products'] if p['quantity'] >= 2 and p['is_active']]
    first = products[0]
    second = next(p for p in products if p['point_id'] != first['point_id'])
    check(urllib.request.urlopen(base + '/api' + first['image_url']).status == 200, 'local media available')
    code, _ = call('/demo/favorite', {'point_id': first['point_id'], 'active': True}, token)
    _, state = call('/demo/state', token=token)
    check(code == 200 and first['point_id'] in state['favorites'], 'favorite persists in database')
    code, _ = call('/orders/', {'user_id': user['user']['id'], 'point_id': first['point_id'],
        'products_id': [second['id']], 'total_price': second['price']}, token)
    check(code == 400, 'cross-point order rejected')
    created = []
    for product in (first, second):
        code, order = call('/orders/', {'user_id': user['user']['id'], 'point_id': product['point_id'],
            'products_id': [product['id']], 'total_price': product['price']}, token)
        check(code == 200, 'order created for point ' + str(product['point_id']))
        code, payment = call('/payments/create', {'order_id': order['id']}, token)
        check(code == 200 and payment['transaction']['status'] == 'completed', 'mock payment completed')
        _, repeated = call('/payments/create', {'order_id': order['id']}, token)
        check(repeated['transaction']['id'] == payment['transaction']['id'], 'payment retry reuses transaction')
        created.append(order)
    _, partner_state = call('/demo/state', token=partner)
    check(all(o['id'] in [p['id'] for p in partner_state['orders']] for o in created), 'orders visible to partner')
    code, _ = call('/orders/' + str(created[0]['id']) + '/refund', {}, token)
    check(code == 200, 'refund completed locally')
    _, state = call('/demo/state', token=token)
    stock = next(p['quantity'] for p in state['products'] if p['id'] == first['id'])
    check(stock == first['quantity'], 'refund restores inventory exactly once')
    code, _ = call('/orders/' + str(created[0]['id']) + '/refund', {}, token)
    check(code == 409, 'repeat refund rejected')
    code, _ = call('/payments/create', {'order_id': created[0]['id']}, token)
    check(code == 409, 'cancelled order cannot be paid')
    for status_name in ('processing', 'completed'):
        code, _ = call('/orders/' + str(created[1]['id']) + '/status', {'status': status_name}, partner, 'PUT')
        check(code == 200, 'partner marks order ' + status_name)
    _, state = call('/demo/state', token=token)
    check(next(o['status'] for o in state['orders'] if o['id'] == created[1]['id']) == 'completed', 'buyer sees partner update')
    code, review = call('/reviews/', {'point_id': first['point_id'], 'rating': 5, 'comment': 'Прекрасный свежий бокс. Проверка демонстрации.'}, token)
    check(code == 200, 'review published')
    call('/reviews/' + str(review['id']), token=token, method='DELETE')
    code, _ = call('/demo/reset', {}, token)
    check(code == 403, 'buyer cannot reset demo')
    code, refreshed = call('/auth/refresh', {'refresh_token': user['refresh_token']})
    check(code == 200, 'refresh rotates tokens')
    code, _ = call('/auth/refresh', {'refresh_token': user['refresh_token']})
    check(code == 401, 'old refresh token rejected')
    code, _ = call('/logout', {}, refreshed['access_token'])
    check(code == 200, 'logout revokes session')
    code, _ = call('/demo/state', token=refreshed['access_token'])
    check(code == 401, 'logged-out access token rejected')
    print(f'All {checks} demo checks passed.')


if __name__ == '__main__':
    main()
