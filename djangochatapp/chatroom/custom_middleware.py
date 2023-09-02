from channels.middleware import BaseMiddleware
from channels.db import database_sync_to_async
from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework_simplejwt.exceptions import InvalidToken
from django.contrib.auth.models import AnonymousUser



class CustomJWTAuthMiddleware(BaseMiddleware):
    def __init__(self, inner, *args, **kwargs):
        self.authentication = JWTAuthentication()
        super().__init__(inner, *args, **kwargs)


    async def __call__(self, scope, receive, send):
        try:
            headers = dict(scope["headers"])
            if b"authorization" in headers:
                token = headers[b"authorization"].decode().split()[1]
            else:
                raise InvalidToken('No token found.')

            # Validate the token
            validated_token = self.authentication.get_validated_token(token)
            user = await database_sync_to_async(self.authentication.get_user)(validated_token)
    
            # Set the user in the scope
            scope['user'] = user
        except InvalidToken:
            scope['user'] = AnonymousUser()

        return await super().__call__(scope, receive, send)
