import asyncio
from aioquic.asyncio import connect

async def check_quic_connection():
    try:
        async with connect('google.com', 443) as quic:
            print("QUIC connection successful")
    except Exception as e:
        print(f"QUIC connection failed: {str(e)}")

loop = asyncio.get_event_loop()
loop.run_until_complete(check_quic_connection())
