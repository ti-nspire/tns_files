import RK4_Class
import time
import ti_system as tsys
import ti_draw as td
from math import sin as SIN
from math import cos as COS
from math import pi as PI

class PEND_SINGLE_Class:
  def __init__(self, radius, init_radian, init_vel, h, div):
    td.use_buffer()

    # 引数を定数としてとっておく。リセット時に使う。
    self.RADIUS = radius
    self.RADIAN = init_radian
    self.VEL = init_vel
    self.ARGs = [self.RADIUS, self.RADIAN, self.VEL, h, div]

    # 画面のx軸、y軸の範囲を設定する。
    # ここではx軸を-1.65～1.65、y軸を-1.1～1.1にした。
    self.WIDTH, self.HIGHT = td.get_screen_dim()
    ASPECT = self.WIDTH / self.HIGHT
    self.Y_MIN, self.Y_MAX = -radius * 1.1, radius * 1.1
    self.X_MIN, self.X_MAX = self.Y_MIN * ASPECT, self.Y_MAX * ASPECT
    td.set_window(self.X_MIN, self.X_MAX, self.Y_MIN, self.Y_MAX)

    # 質点の描画半径。シミュレーションとは無関係。
    self.MASS_R = 0.1

    #更新すべき初期値を設定する。
    self.t0 = 0    
    self.radian = init_radian
    self.vel = init_vel
    self.inits = [init_radian, init_vel]

    # 解くべき微分方程式を定義する。
    def dotRadian(t, radian, vel):
      return vel
    def dotVel(t, radian, vel):
      return (-9.80665 / self.RADIUS) * SIN(radian)
    self.FUNCS = [dotRadian, dotVel]

    # 上記の微分方程式を上記の初期値で解くための函数を実体化する。
    self.rk4 = RK4_Class.RK4_Class(self.FUNCS, self.inits, h, div)

  def update(self):
    self.rk4.update()
    self.t0 = self.rk4.t0
    self.radian = self.rk4.inits[0]
    self.vel = self.rk4.inits[1]

  def draw(self):
    td.clear()
    
    x = self.RADIUS * SIN(self.radian)
    y = self.RADIUS * -COS(self.radian)
    td.draw_line(0, 0, x, y)
    td.draw_circle(x, y, self.MASS_R)
    
    td.draw_text(self.X_MIN, self.Y_MAX-0.2, "radius: "+str(self.RADIUS)+" m")
    td.draw_text(self.X_MIN, self.Y_MAX-0.3, "sec: "+str(self.t0))
    td.draw_text(self.X_MIN, self.Y_MAX-0.4, "radian: "+str(self.radian))
    td.draw_text(self.X_MIN, self.Y_MIN+0.15, "To reset, press the esc key.")
    td.draw_text(self.X_MIN, self.Y_MIN+0, "To pause or resume, press the enter key.")

    td.paint_buffer()

  def update_and_draw(self):
    self.update()
    self.draw()

  def wait_for_pressing_enter(self):
    while tsys.get_key() != "enter":
      pass

  def reset(self):
    self.__init__(*self.ARGs)
    self.draw()
    
  def pause_or_resume(self):
    while True:
      key = tsys.get_key()
      if key == "esc":
        self.reset()
      if key == "enter":
        break

  def start_sim(self):
    self.draw()
    self.wait_for_pressing_enter()
    while True:
      self.update_and_draw()
      key = tsys.get_key()
      if key == "enter":
        self.pause_or_resume()
      if key == "esc":
        self.reset()
      #time.sleep_ms(20)
      
def main():
  # 引数は(半径, 初期角度, 初期角速度, ステップ, 1ステップの内部分割数)
  pend_single = PEND_SINGLE_Class(1, PI * 0.999 , 0, 1/2**4, 8)
  pend_single.start_sim()
