TEAM_NAME="relay"

import zmq

def bot_to_gamestate(bot):
    if bot.is_blue:
        turn = bot.turn * 2
        teams = [bot, bot.enemy[0]]
        bots = [bot._bots['team'][0], bot._bots['enemy'][0], bot._bots['team'][1], bot._bots['enemy'][1]]
    else:
        turn = bot.turn * 2 + 1
        teams = [bot.enemy[0], bot]
        bots = [bot._bots['enemy'][0], bot._bots['team'][0], bot._bots['enemy'][1], bot._bots['team'][1]]

    bot_was_killed = [False] * 4 # TODO

    game_state = {
        "bots": [b.position for b in bots],
        "turn": turn,
        "gameover": False, # otherwise there is no bot
        "score": [t.score for t in teams],
        "food": [t.food for t in teams],
        "walls": bot.walls,
        "round": bot.round,
        "kills": [b.kills for b in bots],
        "deaths": [b.deaths for b in bots],
        "bot_was_killed": bot_was_killed,
        "errors": [[], []],
        "fatal_errors": [[], []],
        "noise_radius": 0,
        "sight_distance": 0,
        "rnd": None,
        "team_names": [t.team_name for t in teams],
        "timeout_length": 3 # TODO
    }
    return game_state

class State():
    def __init__(self):
        self.ctx = zmq.Context()
        self.socket = self.ctx.socket(zmq.PAIR)
        self.socket.connect("tcp://192.168.1.14:5555")
        self.pollin = zmq.Poller()
        self.pollin.register(self.socket, zmq.POLLIN)
        self.pollout = zmq.Poller()
        self.pollout.register(self.socket, zmq.POLLOUT)

    def send(self, bot):
        sock = dict(self.pollout.poll(2000))
        if sock.get(self.socket) == zmq.POLLOUT:
            self.socket.send_json(bot_to_gamestate(bot))

    def recv(self):
        sock = dict(self.pollin.poll(2000))
        if sock.get(self.socket) == zmq.POLLIN:
            return self.socket.recv_json()


def move(bot, state):
    if not state:
        state = State()

    state.send(bot)
    state.recv()

    return bot.position, state
