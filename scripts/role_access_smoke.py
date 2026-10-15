"""Verify all presentation roles, guest isolation and support access over HTTP."""
import presentation_services_smoke as api


def main():
    tokens = {}
    ids = set()
    expected = {
        'user': 'demo', 'partner': 'partner1', 'admin': 'adminuser',
        'support': 'support1', 'guest': 'guestuser',
    }
    for role, username in expected.items():
        status, session = api.call('/demo/session', {'role': role})
        api.check(status == 200 and session['user']['role'] == role
                  and session['user']['username'] == username, f'{role} opens its own account')
        tokens[role] = session['access_token']
        ids.add(session['user']['id'])
    api.check(len(ids) == 5, 'all five roles belong to separate accounts')
    status, _ = api.call('/demo/session', {'role': 'superuser'})
    api.check(status == 400, 'unknown role rejected')
    status, catalog = api.call('/demo/catalog')
    api.check(status == 200 and len(catalog['points']) == 30
              and not catalog['orders'] and not catalog['favorites'], 'guest catalog contains no personal history')
    for path in ['/demo/state', '/orders/', '/demo/support']:
        status, _ = api.call(path, token=tokens['guest'])
        api.check(status == 403, f'guest cannot access {path}')
    status, _ = api.call('/demo/support', {'topic': 'Вопрос', 'message': 'Нельзя отправить от гостя.'}, tokens['guest'])
    api.check(status == 403, 'guest cannot create a support ticket')
    status, ticket = api.call('/demo/support', {'topic': 'Другой вопрос',
        'message': 'Подскажите, как сохранить любимое заведение?'}, tokens['user'])
    api.check(status == 201 and ticket['order_id'] is None, 'buyer can ask a general question')
    status, tickets = api.call('/demo/support', token=tokens['support'])
    api.check(status == 200 and any(t['id'] == ticket['id'] for t in tickets), 'support sees general questions')
    _, partner_tickets = api.call('/demo/support', token=tokens['partner'])
    api.check(all(t['id'] != ticket['id'] for t in partner_tickets), 'partner cannot read general support questions')
    status, _ = api.call(f'/demo/support/{ticket["id"]}/reply', {'response': 'Ответ чужого заведения.'}, tokens['partner'])
    api.check(status == 404, 'partner cannot reply to a general support question')
    response = 'Нажмите сердечко на карточке предложения — заведение появится в избранном.'
    status, _ = api.call(f'/demo/support/{ticket["id"]}/reply', {'response': response}, tokens['support'])
    api.check(status == 200, 'support can reply to a general question')
    _, tickets = api.call('/demo/support', token=tokens['user'])
    api.check(any(t['id'] == ticket['id'] and t['response'] == response for t in tickets), 'buyer receives support reply')
    status, _ = api.call('/action-logs/', token=tokens['support'])
    api.check(status == 403, 'support cannot access administrator logs')
    status, tickets = api.call('/demo/support', token=tokens['admin'])
    api.check(status == 200 and any(t['id'] == ticket['id'] for t in tickets), 'administrator sees support tickets')
    print(f'All {api.checks} role access checks passed.')


if __name__ == '__main__':
    main()
