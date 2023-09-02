from django.urls import path

from . import consumers

websocket_urlpatterns = [ 
    path('chat/<str:groupName>/', consumers.MyAsyncWebsocketConsumer.as_asgi()),
]