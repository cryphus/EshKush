"""Exercise local sign-in challenges and the buyer/partner support round trip."""
import json
import sys
import time
import urllib.request
import urllib.error

base = (sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:8080').rstrip('/')
checks = 0


def check(condition, label):
    global checks
    assert condition, label
    checks += 1
    print('PASS:', label)


def call(path, body=None, token=None):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    request = urllib.request.Request(base + '/api' + path, headers=headers,
        data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(request, timeout=20) as result:
            return result.status, json.load(result)
    except urllib.error.HTTPError as error:
        return error.code, json.load(error)


def session(role):
    status, result = call('/demo/session', {'role': role})
    assert status == 200
    return result['access_token']


def main():
    code, _ = call('/demo/auth/challenge', {'phone': '123', 'role': 'user'})
    check(code == 400, 'malformed phone rejected')
    phone = '+7999' + str(int(time.time()))[-7:]
    code, _ = call('/demo/auth/challenge', {'phone': phone, 'role': 'admin'})
    check(code == 400, 'unsupported role rejected')
    code, challenge = call('/demo/auth/challenge', {'phone': phone, 'role': 'partner'})
    check(code == 200 and len(challenge['code_preview']) == 6, 'local code issued')
    code, _ = call('/demo/auth/challenge', {'phone': phone, 'role': 'partner'})
    check(code == 429, 'resend cooldown enforced')
    wrong_code = '000000' if challenge['code_preview'] != '000000' else '000001'
    code, _ = call('/demo/auth/verify', {'challenge_id': challenge['challenge_id'], 'code': wrong_code})
    check(code == 400, 'incorrect code rejected')
    body = {'challenge_id': challenge['challenge_id'], 'code': challenge['code_preview']}
    code, verified = call('/demo/auth/verify', body)
    check(code == 200 and verified['user']['role'] == 'partner', 'code signs in the bound role')
    code, _ = call('/demo/auth/verify', body)
    check(code == 400, 'verified code cannot be reused')
    buyer = session('user')
    partner = verified['access_token']
    _, state = call('/demo/state', token=buyer)
    order = state['orders'][0]
    code, _ = call('/demo/support')
    check(code == 401, 'support requires authentication')
    code, _ = call('/demo/support', {'topic': 'Вопрос', 'message': 'x', 'order_id': order['id']}, buyer)
    check(code == 400, 'empty support request rejected')
    code, ticket = call('/demo/support', {'topic': 'Вопрос об оплате',
        'message': 'Подскажите время получения моего заказа, пожалуйста.', 'order_id': order['id']}, buyer)
    check(code == 201 and ticket['status'] == 'open', 'support request saved')
    _, tickets = call('/demo/support', token=buyer)
    check(any(t['id'] == ticket['id'] for t in tickets), 'buyer sees saved request')
    code, guest = call('/login', {'username': 'demo_guest_1', 'password': 'Demo@1234'})
    assert code == 200
    _, guest_tickets = call('/demo/support', token=guest['access_token'])
    check(all(t['id'] != ticket['id'] for t in guest_tickets), 'other buyers cannot read request')
    code, _ = call('/demo/support', {'topic': 'Вопрос', 'message': 'Чужой заказ для проверки доступа.', 'order_id': order['id']}, guest['access_token'])
    check(code == 404, 'ticket cannot reference another buyer order')
    code, _ = call(f'/demo/support/{ticket["id"]}/reply', {'response': 'Ответ без прав запрещён.'}, buyer)
    check(code == 403, 'buyer cannot impersonate support')
    _, partner_tickets = call('/demo/support', token=partner)
    check(any(t['id'] == ticket['id'] for t in partner_tickets), 'assigned partner sees request')
    answer = 'Заказ готов. Назовите код получения сотруднику, пожалуйста.'
    code, updated = call(f'/demo/support/{ticket["id"]}/reply', {'response': answer}, partner)
    check(code == 200 and updated['status'] == 'answered', 'partner reply saved')
    _, buyer_tickets = call('/demo/support', token=buyer)
    check(any(t['id'] == ticket['id'] and t['response'] == answer for t in buyer_tickets), 'reply delivered back to buyer')
    print(f'All {checks} presentation service checks passed.')


if __name__ == '__main__':
    main()
