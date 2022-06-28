const getDiscountRatio = (pi, pf, ts) => {
  let d = 0;
  ts = ts * 60;

  d = (pi - pf) / ts;

  console.log(d);
  return d;
};

getDiscountRatio(1000, 500, 60);

module.exports = getDiscountRatio;
