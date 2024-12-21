unit Usoil_heat; // Bodentemperaturmodell aus DAISY abgeleitet, noch nicht fertig !!!

interface

uses
  UMod, UState, UlayeredSoil, classes;

const
  water_heat_capacity = 4.2e7; /// [erg/cm^3/dg C]
  rho_water = 1.0; /// [g/cm^3]
  rho_ice = 0.917; /// [g/cm^3]
  latent_heat_of_fussion = 3.35e9; /// [erg/g]
  gravity = 982.; /// [cm/s^2]

type
  state_t =  (liquid, freezing, frozen, thawing);


TSoilHeat = class (TLayeredSoil)

private

  q,
  capacity,
  C_apparent;

  S : Array[1..max_comp] of real;

  procedure update_freezing_points;

  function update_state:boolean;

  function calculate_freezing_rate (i: integer): real;
  function check_state: boolean;
  procedure force_state;
  procedure solve (const Time&, const Soil&, const SoilWater&,
	      const Surface&, const Weather&);
  procedure calculate_heat_flux;
  procedure energy (from_, to_: real) const;
  procedure set_energy (from_, to_, energy: real);
  procedure bottom;



protected


public

  h_frozen : real;
  enable_ice : boolean;

  // State
  T_old,
  T : TSoilStateArray;

  T_top,
  T_top_old
  T_bottom : TVar;


  T_freezing,
  T_thawing,
  freezing_rate : TVarArray;


  state : Array[1..max_comp] of State_t;


procedure createAll; override;

procedure init(var GlobMod:Tmod); override;


procedure createAll; override;

procedure CalcRates; override;


published


end;


procedure Register;

implementation

uses
  math, dialogs, SysUtils;



Procedure TSoilHeat.Calcrates;

var
  changed, changed_again : boolean;

begin
  // Update freezing and melting points.
  update_freezing_points;

  // Solve with old state.
  T_old := T;
  solve (time, soil, soil_water, surface, weather);

  // Check if ice is enabled.
  if (enable_ice = true)
    return;

  // Update state according to new temperatures.
  changed := update_state (soil, soil_water);

  if (changed)
    begin
      // Solve again with new state.
      T := T_old;
      solve (time, soil, soil_water, surface, weather);

      // Check if state match new temperatures.
      changed_again := check_state (soil);
      
      if (changed_again)
	begin
	  // Force temperatures to match state.
	  force_state (soil);
	end
    end
  // Update ice in water.
  soil_water.freeze (soil, freezing_rate);
end
  
procedure TSoilHeat.update_freezing_points;

var
  i : integer;
  theta,
  x_ice,
  h,
  h_ice,
  h_melt : real;

begin
  for i := 0 to n_comp do begin
      Theta := soil_water.Theta (i);
      X_ice := soil_water.X_ice (i);
      h := soil_water.h (i);
      h_ice := soil_water.h_ice (i);
      h_melt := max (h_ice, h);

      T_thawing[i]  := min (0.0, 273. *  h_melt / (latent_heat_of_fussion /gravity - h_melt));
      T_freezing[i] := min (T_thawing[i] - 0.01, 273. *  h / (latent_heat_of_fussion / gravity - h));

      capacity[i] := soil.heat_capacity (i, Theta, X_ice);

      Case state[i] of
	liquid:
	  break;
	freezing:
	  if (Theta < soil.Theta (i, h_frozen, 0.0))
	    state[i] := frozen;
	  break;
	frozen:
	  if (Theta > soil.Theta (i, h_frozen + 1000.0, 0.0))
	    state[i] := freezing;
	  break;
	thawing:
	  break;
      end;
    end
end;



function TSoilHeat.update_state (const Soil& soil,
					const SoilWater& soil_water): boolean;

var
  i      : integer;
  chaned : boolean;

begin
  changed := false;

  for i := 0 to n_comp do begin
      case state[i] of

	freezing:
	  if (T[i] < T_freezing[i])
	    begin
	      // Find freezing rate.
	      freezing_rate[i] := calculate_freezing_rate (soil, soil_water, i);

	      if (freezing_rate[i] < 0.0)
		freezing_rate[i] := 0.0;

	      // Check if there are sufficient water.
	      const double Theta_min := soil.Theta (i, h_frozen - 1000.0, 0.0);
	      daisy_assert (Theta_min >= soil.Theta_res (i));
	      const double available_water := soil_water.Theta (i) - Theta_min;
	      if (freezing_rate[i] * dt > available_water)
		freezing_rate[i] := max (0.0, available_water / dt);

	      // We have used the energy.
	      T[i] := T_freezing[i];
	    end
	  else if (T[i] > T_thawing[i])
	    begin
	      if (soil_water.X_ice_total (i) > 0.0)
		state[i] := thawing;
	      else
		state[i] := liquid;

	      changed := true;
	      freezing_rate[i] := 0.0;
	    end
	  else
	    freezing_rate[i] := 0.0;
	  daisy_assert (-freezing_rate[i] * rho_water / rho_ice
		  <= soil_water.X_ice_total (i));
	  break;
	frozen:
	  freezing_rate[i] := 0.0;
	  if (T[i] > T_thawing[i])
	    begin
	      if (soil_water.X_ice_total (i) > 0.0)
		state[i] := thawing;
	      else
		state[i] := liquid;
	      changed := true;
	    end
	  break;
	thawing:
	  if (T[i] > T_thawing[i])
	    begin
	      freezing_rate[i] := calculate_freezing_rate (soil, soil_water, i);
	      if (freezing_rate[i] > 0.0)
		freezing_rate[i] := 0.0;

	      const double X_ice_total := soil_water.X_ice_total (i);
	      const double ice_water := X_ice_total * rho_ice / rho_water;
	      if (-freezing_rate[i] * dt >= ice_water)
		begin
		  freezing_rate[i] := -ice_water / dt;
		  daisy_assert (freezing_rate[i] <= 0.0);

		  state[i] := liquid;
		end
	      // We have used the energy.
	      T[i] := T_thawing[i];

	    end
	  else if (T[i] < T_freezing[i])
	    begin
	      state[i] := freezing;
	      changed := true;
	      freezing_rate[i] := 0.0;
	    end
	  else
	    freezing_rate[i] := 0.0;
	  daisy_assert (-freezing_rate[i] * rho_water / rho_ice
		  <= soil_water.X_ice_total (i) * 1.0001);
	  break;
	liquid:
	  freezing_rate[i] := 0.0;
	  if (T[i] < T_freezing[i])
	    begin
	      state[i] := freezing;
	      changed := true;
	    end
	  break;
	end
    end
  return changed;
end

function TSoilHeat.calculate_freezing_rate (const Soil& soil,
						   const SoilWater& soil_water,
						   unsigned int i);

var
  T_mean,
  dt,
  dq,
  dz,
  s : real

begin
  T_mean := (T[i] + T_old[i]) / 2.0;
  dT := T[i] - T_old[i];
  dq := q[i] - q[i+1];
  dz := soil.dz (i);
  S  := soil_water.S_sum (i) - soil_water.S_ice (i) * rho_ice / rho_water;
  Sh := water_heat_capacity * rho_water * S * T_mean;
  result := (1.0 / (latent_heat_of_fussion * rho_ice))
            * (capacity[i] * dT / dt + dq / dz + Sh);
end

bool
SoilHeat::Implementation::check_state (const Soil& soil) const
begin
  for (unsigned int i := 0; i < soil.size (); i++)
    begin
      switch (state[i])
	begin
	case freezing:
	  if (T[i] > T_freezing[i])
	    return true;
	  break;
	case frozen:
	  if (T[i] > T_thawing[i])
	    return true;
	  break;
	case thawing:
	  if (T[i] < T_thawing[i])
	    return true;
	  break;
	case liquid:
	  if (T[i] < T_freezing[i])
	    return true;
	  break;
	end
    end
  return false;
end

void
SoilHeat::Implementation::force_state (const Geometry& geometry)
begin
  for (unsigned int i := 0; i < geometry.size (); i++)
    begin
      switch (state[i])
	begin
	case freezing:
	  T[i] := T_freezing[i];
	  break;
	case frozen:
	  if (T[i] > T_thawing[i])
	    T[i] := T_thawing[i];
	  break;
	case thawing:
	  T[i] := T_thawing[i];
	  break;
	case liquid:
	  if (T[i] < T_freezing[i])
	    T[i] := T_freezing[i];
	  break;
	end
    end
end

void
SoilHeat::Implementation::solve (const Time& time,
				 const Soil& soil,
				 const SoilWater& soil_water,
				 const Surface& surface,
				 const Weather& weather)
begin
  // Border conditions.
  T_bottom := bottom (time, weather); // BUGLET: Should be time - 1 hour.
		     
  const double T_top_new := surface.temperature ();
  
  if (T_top < -400.0)
    T_top := T_top_new;

  int size := soil.size ();

  // Tridiagonal matrix.
  vector<double> a (size, 0.0);
  vector<double> b (size, 0.0);
  vector<double> c (size, 0.0);
  vector<double> d (size, 0.0);

  // Inner nodes.
  for (int i := 0; i < size; i++)
    begin
      // Soil Water
      const double Theta := soil_water.Theta (i);
      const double X_ice := soil_water.X_ice (i);
      const double h := soil_water.h (i);
      const double h_ice := soil_water.h_ice (i);

      const int prev := i - 1;
      const int next := i + 1;

      // Calculate average heat capacity and conductivity.
      const double conductivity := soil.heat_conductivity (i, Theta, X_ice);

      // Calculate distances.
      const double dz_next 
	:= (i == size - 1)
	? soil.z (i) - soil.z (prev)
	: soil.z (next) - soil.z (i);
      const double dz_prev 
	:= (i == 0)
	? soil.z (i) - 0.0
	: soil.z (i) - soil.z (prev);
      const double dz_both := dz_prev + dz_next;

      // Calculate temperature differences.
      const double dT_next := ((i == size - 1)
			      ? T_bottom - T[i] 
			      : T[next] - T[i]);
      const double dT_prev := (i == 0) ? T[i] - T_top : T[i] - T[prev];
      const double dT_both := dT_prev + dT_next;
      
      // Calculate conductivity gradient.
      double gradient;
      if (i == 0)
	gradient := 0.0;
      else if (i == size - 1)
	gradient 
	  := (soil.heat_conductivity (i, 
				     soil_water.Theta (i),
				     soil_water.X_ice (i))
	     - soil.heat_conductivity (prev, 
				       soil_water.Theta (prev),
				       soil_water.X_ice (prev)))
	  / dz_prev;
      else
	gradient 
	  := (soil.heat_conductivity (next, 
				     soil_water.Theta (next),
				     soil_water.X_ice (next))
	     - soil.heat_conductivity (prev, 
				       soil_water.Theta (prev),
				       soil_water.X_ice (prev)))
	  / dz_both;
      
      // Computational,
      const double Cx := gradient
	+ water_heat_capacity
	* (soil_water.q (i) + soil_water.q (next)) / 2.0;

      // Heat capacity including thawing/freezing.
      C_apparent[i] := capacity[i];
      switch (state[i])
	begin
	case freezing:
	  C_apparent[i] += (latent_heat_of_fussion * latent_heat_of_fussion
			    * rho_water * soil.Cw2 (i, h)
			    / (273. * gravity));
	  break;
	case thawing:
	  C_apparent[i] += (latent_heat_of_fussion * latent_heat_of_fussion
			    * rho_water * soil.Cw2 (i, h_ice)
			    / (273. * gravity));
	  break;
	case liquid:
	case frozen:
	  break;
	end

      // Setup tridiagonal matrix.
      a[i] := - conductivity / dz_both / dz_prev + Cx / 2.0 / dz_both;
      b[i] := C_apparent[i] / dt
	+ conductivity / dz_both * (1.0 / dz_next + 1.0 / dz_prev);
      c[i] := - conductivity / dz_both / dz_next - Cx / 2.0 / dz_both;
      const double x2 := dT_next / dz_next - dT_prev/ dz_prev;
      if (i == 0)
	d[i] := T[i] * C_apparent[i] / dt
	  + conductivity / soil.z (1) * (x2 + T_top_new / soil.z (0))
	  + Cx * (T[1] - T_top + T_top_new) / (2.0 * soil.z (1));
      else
	d[i] := T[i] * C_apparent[i] / dt + (conductivity / dz_both) * x2
	  + Cx * dT_both / dz_both / 2.0;
      
      if (state[i] == freezing || state[i] == thawing)
	d[i] -= latent_heat_of_fussion * rho_water
	  * (soil_water.q (i) - soil_water.q (next)) / soil.dz (i) / dt;

      // External heat source.
      d[i] += S[i];
    end
  d[size - 1] := d[size - 1] - c[size - 1] * T_bottom;
  tridia (0, size, a, b, c, d, T.begin ());
  T_top_old := T_top;
  T_top := T_top_new;
  daisy_assert (T[0] < 50.0);

  calculate_heat_flux (soil, soil_water);
end

void
SoilHeat::Implementation::calculate_heat_flux (const Soil& soil,
					       const SoilWater& soil_water)
begin
  // Top and inner nodes.
  double T_prev := (T_top + T_top_old) / 2.0;
  double z_prev := 0.0;
  for (unsigned int i := 0; i < soil.size (); i++)
    begin
      const double Theta := soil_water.Theta (i);
      const double X_ice := soil_water.X_ice (i);
      const double K := soil.heat_conductivity (i, Theta, X_ice);
      const double T_next := (T[i] + T_old[i]) / 2.0;
      const double dT := T_prev - T_next;
      const double dz := z_prev - soil.z (i);
      const double q_water := soil_water.q (i);
      const double T := (T_prev + T_next) / 2.0;

      q[i] := - K * dT/dz + water_heat_capacity * rho_water *  q_water * T;
      T_prev := T_next;
      z_prev := soil.z (i);
    end
  // Lower boundary.
  const unsigned int i := soil.size ();
  const unsigned int prev := i - 1U;
  const double Theta := soil_water.Theta (prev);
  const double X_ice := soil_water.X_ice (prev);
  const double K := soil.heat_conductivity (prev, Theta, X_ice);
  const double T_next := T_bottom;
  const double dT := T_prev - T_next;
  const double dz := soil.z (prev-1U) - soil.z (prev);
  const double q_water := soil_water.q (i);
  const double T := (T_prev + T_next) / 2.0;

  q[i] := - K * dT/dz - water_heat_capacity * rho_water *  q_water * T;
end
  

double 
SoilHeat::Implementation::energy (const Soil& soil,
				  const SoilWater& soil_water,
				  double from, double to) const
begin
  double amount := 0.0;
  double old := 0.0;

  for (unsigned int i := 0; i < soil.size () && old > to ; i++)
    begin
      if (soil.zplus (i) < from)
	begin
	  const double height := (min (old, from) - max (soil.zplus (i), to));
	  const double C := soil.heat_capacity (i, soil_water.Theta (i), soil_water.X_ice (i));
	  amount += C * T[i] * height;
	end
      old := soil.zplus (i);
    end
  return amount;
end

void
SoilHeat::Implementation::set_energy (const Soil& soil,
				      const SoilWater& soil_water, 
				      double from, double to, double energy)
var
  capacity,
  old      : real;

begin
  // Find total energy capacity.
  double capacity := 0.0;
  double old := 0.0;

  for (unsigned int i := 0; i < soil.size () && old > to ; i++)
    begin
      if (soil.zplus (i) < from)
	begin
	  const double height := (min (old, from) - max (soil.zplus (i), to));
	  capacity += soil.heat_capacity (i, soil_water.Theta (i), 
					  soil_water.X_ice (i)) * height;
	end
      old := soil.zplus (i);
    end
  
  // Distribute temperature evenly.
  const double average := energy / capacity / (to - from);
  old := 0.0;

  for (unsigned int i := 0; i < soil.size () && old > to ; i++)
    begin
      if (soil.zplus (i) < from)
	begin
	  const double height := (min (old, from) - max (soil.zplus (i), to));
	  T[i] := (height * average + (soil.dz (i) - height)* T[i]) 
	    / soil.dz (i);
	end
      old := soil.zplus (i);
    end
end

double 
SoilHeat::Implementation::bottom

 (const Time& time,
				  const Weather& weather) const 
begin
  return weather.T_normal (time, delay);
end

bool
SoilHeat::Implementation::check (unsigned n, Treelog& err) const
begin
  bool ok := true;
  if (T.size () != n)
    begin
      std::ostringstream tmp;
      tmp << "You have " << n << " intervals but " 
	     << T.size () << " T values";
      err.entry (tmp.str ());
      ok := false;
    end
  return ok;
end

SoilHeat::Implementation::Implementation (const AttributeList& al)
  : h_frozen (al.number ("h_frozen")),
    enable_ice (al.flag ("enable_ice")),
    T_top (al.number ("T_top", -500.0))
begin 
  if (al.check ("S"))
    S := al.number_sequence ("S");
end

void
SoilHeat::Implementation::initialize (const AttributeList& al, 
				      const Soil& soil, 
				      const Time& time, 
				      const Weather& weather, Treelog& out)
begin
  // Freezing point.
  T_freezing.insert (T_freezing.end (), soil.size (), 0.0);
  T_thawing.insert (T_thawing.end (), soil.size (), 0.0);
  state.insert (state.end (), soil.size (), liquid);
  freezing_rate.insert (freezing_rate.end (), soil.size (), 0.0);
  q.insert (q.end (), soil.size () + 1U, 0.0);
  capacity.insert (capacity.end (), soil.size (), 0.0);
  C_apparent.insert (C_apparent.end (), soil.size (), 0.0);
  while (S.size () < soil.size ())
    S.push_back (0.0);

  // Fetch average temperatur.
  const double rad_per_day := 2.0 * M_PI / 365.0;

  // Fetch initial T.
  soil.initialize_layer (T, al, "T", out);

  // Calculate delay.
  const double pF_2_0 := -100.0;
  double k := 0;
  double C := 0;
  
  for (unsigned int i := 0; i < soil.size (); i++)
    begin
      const double Theta_pF_2_0 := soil.Theta (i, pF_2_0, 0.0);
      k += soil.dz (i) * soil.heat_conductivity (i, Theta_pF_2_0, 0.0);
      C += soil.dz (i) * soil.heat_capacity (i, Theta_pF_2_0, 0.0);
      const double a := k / C;
      delay := soil.zplus (i) / sqrt (24.0 * 2.0 * a / rad_per_day);

      // Fill out T if necessary.
      if (T.size () <= i)
	T.push_back (bottom (time, weather));
    end

  // We check for this in SoilHeat::check ().
  // daisy_assert (T.size () == soil.size ());
end



function TSoilHeat.top_flux (const Soil& soil, const SoilWater& soil_water): real;

var
  k : real;

begin
  k  := soil.heat_conductivity (0, soil_water.Theta (0), soil_water.X_ice (0))
    * 1e-7 * 1e4 / 3600.0;	// erg/h/ cm/ K -> W/m^2/K
  result := k * (T (0) - T (1)) / (soil.z (0) - soil.z (1));
end



double 
SoilHeat::energy (const Soil& soil,
		  const SoilWater& soil_water,
		  double from, double to) const
begin
  return impl.energy (soil, soil_water, from, to);
end

void
SoilHeat::set_energy (const Soil& soil,
		      const SoilWater& soil_water, 
		      double from, double to, double energy)
begin
  impl.set_energy (soil, soil_water, from, to, energy);
end

void
SoilHeat::swap (const Soil& soil, double from, double middle, double to)
begin
  // This will only work right if the water is also swaped.
  // There *might* be a small error on the top and bottom nodes, but I
  // believe it should work as long as the energy is directly
  // proportional with the water content.
  soil.swap (impl.T, from, middle, to);
end
  
void
SoilHeat::set_source (unsigned int i, double value)
begin impl.S[i] := value; end




function TSoilHeat.check (unsigned n, Treelog& err) const

begin
  return impl.check (n, err);
end



SoilHeat::SoilHeat (const AttributeList& al)
  : impl (*new Implementation (al))
begin end


void
SoilHeat::initialize (const AttributeList& al, 
		      const Soil& soil, const Time& time, 
		      const Weather& weather, Treelog& out)
begin impl.initialize (al, soil, time, weather, out); end

SoilHeat::~SoilHeat ()
begin
  delete &impl;
end

static Submodel::Register 
soil_heat_submodel ("SoilHeat", SoilHeat::load_syntax);
