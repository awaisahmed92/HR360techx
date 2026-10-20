(function () {
  var SS_RATE = 0.062;
  var SS_BASE = 184500;
  var MED_RATE = 0.0145;
  var ADDL_MED_RATE = 0.009;
  var ADDL_MED_THRESHOLD = 200000;
  var FUTA_NET = 0.006;
  var FUTA_BASE = 7000;

  var standard = {
    mfj: [[0, 19300, 0, 0], [19300, 44100, 0, 0.10], [44100, 120100, 2480, 0.12], [120100, 230700, 11600, 0.22], [230700, 422850, 35932, 0.24], [422850, 531750, 82048, 0.32], [531750, 788000, 116896, 0.35], [788000, Infinity, 206583.50, 0.37]],
    single: [[0, 7500, 0, 0], [7500, 19900, 0, 0.10], [19900, 57900, 1240, 0.12], [57900, 113200, 5800, 0.22], [113200, 209275, 17966, 0.24], [209275, 263725, 41024, 0.32], [263725, 648100, 58448, 0.35], [648100, Infinity, 192979.25, 0.37]],
    hoh: [[0, 15550, 0, 0], [15550, 33250, 0, 0.10], [33250, 83000, 1770, 0.12], [83000, 121250, 7740, 0.22], [121250, 217300, 16155, 0.24], [217300, 271750, 39207, 0.32], [271750, 656150, 56631, 0.35], [656150, Infinity, 191171, 0.37]]
  };
  var step2 = {
    mfj: [[0, 16100, 0, 0], [16100, 28500, 0, 0.10], [28500, 66500, 1240, 0.12], [66500, 121800, 5800, 0.22], [121800, 217875, 17966, 0.24], [217875, 272325, 41024, 0.32], [272325, 400450, 58448, 0.35], [400450, Infinity, 103291.75, 0.37]],
    single: [[0, 8050, 0, 0], [8050, 14250, 0, 0.10], [14250, 33250, 620, 0.12], [33250, 60900, 2900, 0.22], [60900, 108938, 8983, 0.24], [108938, 136163, 20512, 0.32], [136163, 328350, 29224, 0.35], [328350, Infinity, 96489.63, 0.37]],
    hoh: [[0, 12075, 0, 0], [12075, 20925, 0, 0.10], [20925, 45800, 885, 0.12], [45800, 64925, 3870, 0.22], [64925, 112950, 8077.50, 0.24], [112950, 140175, 19603.50, 0.32], [140175, 332375, 28315.50, 0.35], [332375, Infinity, 95585.50, 0.37]]
  };

  function money(n) {
    return n.toLocaleString("en-US", { style: "currency", currency: "USD" });
  }
  function num(id) {
    var el = document.getElementById(id);
    var v = el ? parseFloat(el.value) : 0;
    return isFinite(v) ? v : 0;
  }
  function tent(table, amount) {
    var row = table[table.length - 1];
    for (var i = 0; i < table.length; i++) {
      if (amount >= table[i][0] && amount < table[i][1]) row = table[i];
    }
    return row[2] + Math.max(0, amount - row[0]) * row[3];
  }

  var salary = document.getElementById("salary-form");
  if (salary) {
    salary.addEventListener("submit", function (e) {
      e.preventDefault();
      var annual = num("hourly") * num("hours") * 52;
      document.getElementById("salary-out").textContent = "Estimated annual pay: " + money(annual) + ". Monthly equivalent: " + money(annual / 12) + ".";
    });
  }

  var ot = document.getElementById("ot-form");
  if (ot) {
    ot.addEventListener("submit", function (e) {
      e.preventDefault();
      var rate = num("ot-rate");
      var hours = num("ot-hours");
      var ca = document.getElementById("ot-ca").checked;
      var pay;
      var note;
      if (ca) {
        var regular = Math.min(hours, 8) * rate;
        var half = Math.min(Math.max(hours - 8, 0), 4) * rate * 1.5;
        var dbl = Math.max(hours - 12, 0) * rate * 2;
        pay = regular + half + dbl;
        note = " California day rule used for this one day only. Weekly overtime can still apply.";
      } else {
        var straight = Math.min(hours, 40) * rate;
        var extra = Math.max(hours - 40, 0) * rate * 1.5;
        pay = straight + extra;
        note = " Federal rule: time and a half after 40 hours in the workweek.";
      }
      document.getElementById("ot-out").textContent = "Estimated gross pay: " + money(pay) + "." + note;
    });
  }

  var cost = document.getElementById("cost-form");
  if (cost) {
    cost.addEventListener("submit", function (e) {
      e.preventDefault();
      var gross = num("cost-gross");
      var annual = gross;
      var ss = Math.min(annual, SS_BASE) * SS_RATE;
      var med = annual * MED_RATE;
      var sutaRate = num("cost-suta") / 100;
      var sutaBase = num("cost-suta-base");
      var suta = sutaBase > 0 ? Math.min(annual, sutaBase) * sutaRate : 0;
      var futa = document.getElementById("cost-futa").checked ? Math.min(annual, FUTA_BASE) * FUTA_NET : 0;
      var total = annual + ss + med + suta + futa;
      document.getElementById("cost-out").textContent =
        "Estimated annual employer cost: " + money(total) +
        " (gross " + money(annual) + ", Social Security " + money(ss) +
        ", Medicare " + money(med) + ", SUTA " + money(suta) + ", FUTA " + money(futa) + ").";
    });
  }

  var pay = document.getElementById("pay-form");
  if (pay) {
    pay.addEventListener("submit", function (e) {
      e.preventDefault();
      var wages = num("pay-wages");
      var periods = parseInt(document.getElementById("pay-freq").value, 10);
      var status = document.getElementById("pay-status").value;
      var checked = document.getElementById("pay-step2").checked;
      var ytd = num("pay-ytd");
      var annual = wages * periods;
      var subtract = checked ? 0 : (status === "mfj" ? 12900 : 8600);
      var adjusted = Math.max(0, annual - subtract);
      var table = (checked ? step2 : standard)[status];
      var annualFit = tent(table, adjusted);
      var fit = annualFit / periods;
      var ssWages = Math.max(0, Math.min(wages, Math.max(0, SS_BASE - ytd)));
      var ss = ssWages * SS_RATE;
      var med = wages * MED_RATE;
      var before = Math.max(0, ADDL_MED_THRESHOLD - ytd);
      var addl = Math.max(0, wages - before) * ADDL_MED_RATE;
      var state = document.getElementById("pay-state").value;
      var stateNote = " State income tax is not calculated. Use that state's withholding tables.";
      if (state === "TX" || state === "FL") stateNote = " " + state + " has no personal income tax, so this estimate uses $0 of state income-tax withholding.";
      var net = wages - fit - ss - med - addl;
      document.getElementById("pay-out").textContent =
        "Estimated this paycheck: federal income tax " + money(fit) +
        ", Social Security " + money(ss) + ", Medicare " + money(med + addl) +
        ", take-home before other deductions " + money(net) + "." + stateNote;
    });
  }
})();
