from channels.generic.websocket import AsyncJsonWebsocketConsumer
from channels.db import database_sync_to_async


class MyAsyncWebsocketConsumer(AsyncJsonWebsocketConsumer):

    async def connect(self):
        print('---------------Connect---------------')
        self.user = self.scope['user']
        
        print(self.scope['user'])
        if self.user.is_authenticated == True:
            # print('Authenticated')
            self.roomName = self.scope['url_route']['kwargs']['groupName']
            # print(self.roomName)
            await self.channel_layer.group_add(self.roomName, self.channel_name)
        else:
            # print('Not Authenticated')
            pass
        await self.accept()
        
        
    

    async def receive_json(self, content, **kwargs):
        print('---------------Receive Data---------------')
        # print(content)
        
        if self.scope['user'].is_authenticated ==  True:
            await self.channel_layer.group_send(
                self.roomName,
                {
                    "type": "room.message",
                    "message": content,
                }
            )
        else:
            print('Not Authenticated')
            await self.send_json(
                [
                    {
                        "userMessage": 'Not Authenticated',
                        'username': 'Anonymous user',
                                   
                    }
                ]
            )
            await self.close()
    
    async def room_message(self, event):
        await self.send_json(
            [{
                "username": self.user.username,
                "userMessage": event["message"],
            },],
        )

