# Python による常微分方程式の数値解法_改良版 / 古典的 Runge-Kutta 法
class RK4_Class:
  def __init__(self, funcs, inits, h, numOfDiv=1):
    _num_of_funcs = len(funcs)

    self.funcs = funcs
    self.t0 = 0
    self.inits = inits
    self.h = h / num_of_div
    self.half_h = self.h / 2
    self.sixth_h = self.h / 6
    self.range_dim = range(_num_of_funcs)
    self.range_div = range(num_of_div)
    self.f = [[0] * _num_of_funcs] * 4
    self.temp = [[0] * _num_of_funcs] * 3

  def update(self):
    for i in self.range_div:
      self.f[0] = [self.funcs[j](self.t0, *self.inits) for j in self.range_dim]
      self.temp[0] = [self.inits[j] + self.half_h * self.f[0][j] for j in self.range_dim]
      self.f[1] = [self.funcs[j](self.t0 + self.half_h, *self.temp[0]) for j in self.range_dim]
      self.temp[1] = [self.inits[j] + self.half_h * self.f[1][j] for j in self.range_dim]
      self.f[2] = [self.funcs[j](self.t0 + self.half_h, *self.temp[1]) for j in self.range_dim]
      self.temp[2] = [self.inits[j] + self.h * self.f[2][j] for j in self.range_dim]
      self.f[3] = [self.funcs[j](self.t0 + self.h , *self.temp[2]) for j in self.range_dim]
      self.inits = [self.inits[j] + self.sixth_h * (self.f[0][j] + 2 * (self.f[1][j] + self.f[2][j]) + self.f[3][j]) for j in self.range_dim]
      self.t0 += self.h
    return self

  def print(self):
    print(self.t0, self.inits)
    return self

########
# test #
########
#if __name__ == "__main__":
def main():
  # 解くべき連立常微分方程式を定義する。
  # 確認のため、厳密解の存在する方程式を定義する。単振り子とは無関係。
  def xDot(t, x, y): # x'(t) = y(t)
    return y
  def yDot(t, x, y): # y'(t) = t - x(t)
    return t - x
  funcs = [xDot, yDot]

  # 従属変数の初期値を指定する。
  x0 = 0
  y0 = 0
  inits = [x0, y0]

  # ステップ幅を指定する。
  h = 0.25 # =1/2**2
  
  # 1ステップだけ計算する函数を実体化して、
  rk4 = RK4_Class(funcs, inits, h)

  # 初期値を何度か更新して確認する。
  while rk4.t0 < 7.5:
    rk4.update().print()
