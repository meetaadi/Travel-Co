/*
# Seed 10 Indian cities with destinations, places, and curated trips

1. Purpose
   Populate the database with curated travel content for 10 Indian cities:
   Delhi, Mumbai, Pune, Nashik, Nagpur, Amravati, Lucknow, Chennai, Hyderabad,
   and Jaipur. Each city gets 3 published trips (Day trip, Long weekend, Vacay)
   with day-by-day activities referencing real places.

2. Data Added
   - 10 destinations (Indian cities) with slugs, blurbs, and cover images.
   - ~60 places (key landmarks per city) with categories and local tips.
   - 30 curated trips (3 per city × 10 cities) published under the existing
     user. Each trip has trip_days and activities.
   - All trips are status='published' so they are visible to all users.

3. Security
   - No schema changes. Uses existing tables and RLS policies.
   - Inserts run with the service role (bypasses RLS) via apply_migration.

4. Notes
   - Idempotent: uses ON CONFLICT (slug) for destinations and NOT EXISTS guards
     for places and trips so re-runs won't create duplicates.
   - All trip INSERTs use RETURNING id to capture the new trip id.
*/

DO $$
DECLARE
  v_user uuid;
  v_delhi uuid; v_mumbai uuid; v_pune uuid; v_nashik uuid; v_nagpur uuid;
  v_amravati uuid; v_lucknow uuid; v_chennai uuid; v_hyd uuid; v_jaipur uuid;
  v_p uuid;
  v_t uuid; v_d uuid;
BEGIN
  SELECT id INTO v_user FROM auth.users WHERE email = 'aaditya160707@gmail.com' LIMIT 1;
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'Seed user not found';
  END IF;

  -- DESTINATIONS (upsert by slug)
  INSERT INTO destinations (name, country, slug, blurb, cover_image) VALUES
    ('New Delhi','India','new-delhi','India''s capital blends Mughal grandeur with wide Lutyens boulevards.','https://images.pexels.com/photos/789750/pexels-photo-789750.jpeg?auto=compress&cs=tinysrgb&h=650&w=940'),
    ('Mumbai','India','mumbai','The city that never sleeps — Bollywood, beaches, and bazaars.','https://images.pexels.com/photos/37890763/pexels-photo-37890763.jpeg?auto=compress&cs=tinysrgb&h=650&w=940'),
    ('Pune','India','pune','Maharashtra''s cultural capital with forts, hills, and a youthful energy.','https://images.pexels.com/photos/15623165/pexels-photo-15623165.jpeg?auto=compress&cs=tinysrgb&h=650&w=940'),
    ('Nashik','India','nashik','Wine country and temple town on the banks of the Godavari.','https://images.pexels.com/photos/23697392/pexels-photo-23697392.jpeg?auto=compress&cs=tinysrgb&h=650&w=940'),
    ('Nagpur','India','nagpur','The Orange City — temples, lakes, and the gateway to central India.','https://images.pexels.com/photos/38087491/pexels-photo-38087491.jpeg?auto=compress&cs=tinysrgb&h=650&w=940'),
    ('Amravati','India','amravati','A quiet Maharashtra city of temples, tiger reserves, and cotton fields.','https://images.pexels.com/photos/11370871/pexels-photo-11370871.jpeg?auto=compress&cs=tinysrgb&h=650&w=940'),
    ('Lucknow','India','lucknow','The City of Nawabs — kebabs, imambaras, and refined Awadhi culture.','https://images.pexels.com/photos/24416541/pexels-photo-24416541.jpeg?auto=compress&cs=tinysrgb&h=650&w=940'),
    ('Chennai','India','chennai','Gateway to the south — Marina Beach, temples, and filter coffee.','https://images.pexels.com/photos/6667281/pexels-photo-6667281.jpeg?auto=compress&cs=tinysrgb&h=650&w=940'),
    ('Hyderabad','India','hyderabad','The City of Nizams — biryani, bazaars, and Golconda''s ramparts.','https://images.pexels.com/photos/11321242/pexels-photo-11321242.jpeg?auto=compress&cs=tinysrgb&h=650&w=940'),
    ('Jaipur','India','jaipur','The Pink City — forts, palaces, and Rajasthani bazaars.','https://images.pexels.com/photos/19867647/pexels-photo-19867647.jpeg?auto=compress&cs=tinysrgb&h=650&w=940')
  ON CONFLICT (slug) DO UPDATE SET
    blurb = EXCLUDED.blurb,
    cover_image = EXCLUDED.cover_image;

  SELECT id INTO v_delhi FROM destinations WHERE slug='new-delhi';
  SELECT id INTO v_mumbai FROM destinations WHERE slug='mumbai';
  SELECT id INTO v_pune FROM destinations WHERE slug='pune';
  SELECT id INTO v_nashik FROM destinations WHERE slug='nashik';
  SELECT id INTO v_nagpur FROM destinations WHERE slug='nagpur';
  SELECT id INTO v_amravati FROM destinations WHERE slug='amravati';
  SELECT id INTO v_lucknow FROM destinations WHERE slug='lucknow';
  SELECT id INTO v_chennai FROM destinations WHERE slug='chennai';
  SELECT id INTO v_hyd FROM destinations WHERE slug='hyderabad';
  SELECT id INTO v_jaipur FROM destinations WHERE slug='jaipur';

  -- ===== DELHI PLACES =====
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_delhi, 'Red Fort', 'Heritage', 'Go early to beat the heat and catch the light-and-sound show at dusk.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_delhi AND name='Red Fort');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_delhi, 'India Gate', 'Monument', 'Best photographed after sunset when the floodlights come on.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_delhi AND name='India Gate');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_delhi, 'Qutub Minar', 'Heritage', 'The rust-free iron pillar nearby has not corroded in 1600 years.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_delhi AND name='Qutub Minar');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_delhi, 'Humayun''s Tomb', 'Heritage', 'The inspiration for the Taj Mahal — arrive by 9am for empty gardens.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_delhi AND name='Humayun''s Tomb');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_delhi, 'Lotus Temple', 'Landmark', 'Closed on Mondays. The silence inside is remarkable.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_delhi AND name='Lotus Temple');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_delhi, 'Chandni Chowk', 'Market', 'Take a cycle-rickshaw ride and try the parathas at Gali Paranthe Wali.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_delhi AND name='Chandni Chowk');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_delhi, 'Jama Masjid', 'Heritage', 'Climb the minaret for a panoramic view of Old Delhi.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_delhi AND name='Jama Masjid');

  -- ===== MUMBAI PLACES =====
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_mumbai, 'Gateway of India', 'Monument', 'Take the first ferry to Elephanta to avoid the crowds.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_mumbai AND name='Gateway of India');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_mumbai, 'Marine Drive', 'Waterfront', 'The Queen''s Necklace glitters best after sunset.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_mumbai AND name='Marine Drive');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_mumbai, 'Elephanta Caves', 'Heritage', 'Wear comfortable shoes — 100+ steps to the caves.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_mumbai AND name='Elephanta Caves');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_mumbai, 'Chhatrapati Shivaji Terminus', 'Heritage', 'Look up at the stained-glass windows inside the ticket hall.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_mumbai AND name='Chhatrapati Shivaji Terminus');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_mumbai, 'Colaba Causeway', 'Market', 'Bargain hard — start at 40% of the asking price.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_mumbai AND name='Colaba Causeway');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_mumbai, 'Bandra Worli Sea Link', 'Landmark', 'Best viewed from Bandra Fort at golden hour.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_mumbai AND name='Bandra Worli Sea Link');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_mumbai, 'Kala Ghoda Art Precinct', 'Culture', 'Visit during the Kala Ghoda Arts Festival in February.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_mumbai AND name='Kala Ghoda Art Precinct');

  -- ===== PUNE PLACES =====
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_pune, 'Shaniwar Wada', 'Heritage', 'The fort was mostly destroyed by fire in 1828; the gates survived.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_pune AND name='Shaniwar Wada');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_pune, 'Aga Khan Palace', 'Heritage', 'Gandhi was imprisoned here; the samadhi of Kasturba Gandhi is in the gardens.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_pune AND name='Aga Khan Palace');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_pune, 'Parvati Hill', 'Viewpoint', '108 steps to the top — go at sunrise for a misty city view.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_pune AND name='Parvati Hill');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_pune, 'Dagadusheth Ganpati Temple', 'Temple', 'The jewel-encrusted idol is insured for crores.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_pune AND name='Dagadusheth Ganpati Temple');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_pune, 'Sinhagad Fort', 'Fort', 'Try the local pithla-bhakri from the fort vendors.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_pune AND name='Sinhagad Fort');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_pune, 'Okayama Friendship Garden', 'Park', 'The most zen spot in Pune — go on a weekday morning.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_pune AND name='Okayama Friendship Garden');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_pune, 'Pataleshwar Cave Temple', 'Heritage', 'An 8th-century rock-cut temple right in the middle of the city.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_pune AND name='Pataleshwar Cave Temple');

  -- ===== NASHIK PLACES =====
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nashik, 'Sula Vineyards', 'Winery', 'Book the vineyard tour + tasting combo; sunset on the deck is magical.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nashik AND name='Sula Vineyards');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nashik, 'Trimbakeshwar Temple', 'Temple', 'One of the 12 Jyotirlingas — expect long queues on weekends.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nashik AND name='Trimbakeshwar Temple');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nashik, 'Panchavati', 'Heritage', 'The Ram Kund ghats are where devotees perform rituals for ancestors.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nashik AND name='Panchavati');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nashik, 'Sula Vineyards Deck', 'Winery', 'Order the Brut Tropicale with paneer tikka.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nashik AND name='Sula Vineyards Deck');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nashik, 'Anjaneri Hills', 'Trek', 'Birthplace of Hanuman per legend — a moderate 2-hour trek.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nashik AND name='Anjaneri Hills');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nashik, 'York Winery', 'Winery', 'A quieter alternative to Sula with excellent reds.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nashik AND name='York Winery');

  -- ===== NAGPUR PLACES =====
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nagpur, 'Deeksha Bhoomi', 'Landmark', 'The largest hollow Buddhist stupa in the world.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nagpur AND name='Deeksha Bhoomi');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nagpur, 'Sitabuldi Fort', 'Fort', 'Open to the public only on Republic Day and Independence Day.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nagpur AND name='Sitabuldi Fort');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nagpur, 'Futala Lake', 'Lake', 'Famous for its bhutta (corn) stalls at sunset.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nagpur AND name='Futala Lake');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nagpur, 'Ramtek Fort Temple', 'Heritage', 'A 1-hour drive from Nagpur — mythological site where Rama rested.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nagpur AND name='Ramtek Fort Temple');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nagpur, 'Maharajbagh Zoo', 'Park', 'A small zoo and garden attached to the agriculture college.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nagpur AND name='Maharajbagh Zoo');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_nagpur, 'Ambazari Lake Garden', 'Park', 'Best jogging track in the city; pedal boats available.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_nagpur AND name='Ambazari Lake Garden');

  -- ===== AMRAVATI PLACES =====
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_amravati, 'Ambadevi Temple', 'Temple', 'The goddess Amba is the namesake of the city.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_amravati AND name='Ambadevi Temple');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_amravati, 'Chikhaldara Hill Station', 'Hill Station', '3-hour drive; the only coffee-growing area in Maharashtra.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_amravati AND name='Chikhaldara Hill Station');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_amravati, 'Melghat Tiger Reserve', 'Wildlife', 'Core area of Project Tiger — book a safari in advance.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_amravati AND name='Melghat Tiger Reserve');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_amravati, 'Wadali Talab', 'Lake', 'A peaceful sunset spot near the city center.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_amravati AND name='Wadali Talab');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_amravati, 'Satidham Temple', 'Temple', 'Famous for its annual Navratri fair.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_amravati AND name='Satidham Temple');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_amravati, 'Gugarnal National Park', 'Wildlife', 'Part of the Melghat range — great for birdwatching.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_amravati AND name='Gugarnal National Park');

  -- ===== LUCKNOW PLACES =====
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_lucknow, 'Bara Imambara', 'Heritage', 'The Bhulbhulaiya labyrinth inside has 489 identical doorways.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_lucknow AND name='Bara Imambara');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_lucknow, 'Chota Imambara', 'Heritage', 'Stunning chandeliers inside — nicknamed the Palace of Lights.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_lucknow AND name='Chota Imambara');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_lucknow, 'Rumi Darwaza', 'Landmark', 'Modeled on Istanbul''s Bab-i-Humayun — go at night when it''s lit up.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_lucknow AND name='Rumi Darwaza');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_lucknow, 'Hazratganj Market', 'Market', 'Try the Tunday kebabs at any local shop here.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_lucknow AND name='Hazratganj Market');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_lucknow, 'British Residency', 'Heritage', 'The ruins of the 1857 siege are left as they were.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_lucknow AND name='British Residency');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_lucknow, 'Ambedkar Memorial Park', 'Park', 'A vast sandstone park best visited at dusk when the elephants glow.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_lucknow AND name='Ambedkar Memorial Park');

  -- ===== CHENNAI PLACES =====
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_chennai, 'Marina Beach', 'Beach', 'The second-longest urban beach in the world — go at 6am.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_chennai AND name='Marina Beach');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_chennai, 'Kapaleeshwarar Temple', 'Temple', 'A Dravidian masterpiece — non-Hindus can walk the outer courtyard.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_chennai AND name='Kapaleeshwarar Temple');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_chennai, 'Fort St. George', 'Heritage', 'India''s oldest surviving British-built fort (1644).'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_chennai AND name='Fort St. George');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_chennai, 'San Thome Basilica', 'Landmark', 'Built over the tomb of St. Thomas the Apostle.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_chennai AND name='San Thome Basilica');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_chennai, 'Mahabalipuram', 'Heritage', 'A 1-hour drive — UNESCO shore temples and rock carvings.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_chennai AND name='Mahabalipuram');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_chennai, 'Egmore Museum', 'Culture', 'Houses the largest collection of South Indian bronzes.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_chennai AND name='Egmore Museum');

  -- ===== HYDERABAD PLACES =====
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_hyd, 'Charminar', 'Monument', 'Climb to the upper floor for a view of the Laad Bazaar rooftops.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_hyd AND name='Charminar');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_hyd, 'Golconda Fort', 'Fort', 'Don''t miss the acoustic clap at the Fateh Darwaza gate.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_hyd AND name='Golconda Fort');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_hyd, 'Hussain Sagar Lake', 'Lake', 'The Buddha statue on the island is reached by boat from Lumbini Park.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_hyd AND name='Hussain Sagar Lake');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_hyd, 'Chowmahalla Palace', 'Heritage', 'The durbar hall chandeliers are spectacular.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_hyd AND name='Chowmahalla Palace');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_hyd, 'Salar Jung Museum', 'Museum', 'The musical clock triggers a parade of toy soldiers every hour.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_hyd AND name='Salar Jung Museum');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_hyd, 'Laad Bazaar', 'Market', 'The best place for Hyderabadi bangles and ittar (perfume).'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_hyd AND name='Laad Bazaar');

  -- ===== JAIPUR PLACES =====
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_jaipur, 'Hawa Mahal', 'Monument', 'Best photographed from the cafe across the street at golden hour.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_jaipur AND name='Hawa Mahal');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_jaipur, 'Amber Fort', 'Fort', 'Take the jeep ride up; the Sheesh Mahal mirrors are the highlight.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_jaipur AND name='Amber Fort');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_jaipur, 'City Palace', 'Heritage', 'The royal family still lives in one wing.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_jaipur AND name='City Palace');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_jaipur, 'Jantar Mantar', 'Heritage', 'The world''s largest stone sundial — a UNESCO site.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_jaipur AND name='Jantar Mantar');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_jaipur, 'Nahargarh Fort', 'Fort', 'Best sunset view over all of Jaipur — go 45 min before sundown.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_jaipur AND name='Nahargarh Fort');
  INSERT INTO places (destination_id, name, category, local_tip)
  SELECT v_jaipur, 'Johari Bazaar', 'Market', 'The place for gemstones, silver, and block-printed textiles.'
  WHERE NOT EXISTS (SELECT 1 FROM places WHERE destination_id=v_jaipur AND name='Johari Bazaar');

  -- ===== TRIP SEEDING =====
  -- Each trip uses RETURNING id INTO v_t to capture the new trip id.

  -- ========== DELHI DAY TRIP ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_delhi AND title='Delhi in a day — Old & New' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_delhi, 'Delhi in a day — Old & New', 'Day trip', 1, '₹2,000–3,500', 2, 'Red Fort to India Gate in one packed, unforgettable day.', 'https://images.pexels.com/photos/789750/pexels-photo-789750.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Heritage walk','Street food','Monuments'], 'Start at Red Fort by 9am — the light is best and the crowds are thinner.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Old Delhi → New Delhi') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Red Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order, local_tip) VALUES (v_d, v_p, 'Explore Red Fort', '09:00', 'Heritage', '₹80', 0, 'Audio guide available at the entrance.');
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Jama Masjid';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order, local_tip) VALUES (v_d, v_p, 'Jama Masjid & Old Delhi', '11:30', 'Heritage', '₹50', 1, 'Walk through Chandni Chowk on the way.');
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Chandni Chowk';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order, local_tip) VALUES (v_d, v_p, 'Lunch at Chandni Chowk', '13:00', 'Food', '₹300', 2, 'Try the parathas at Gali Paranthe Wali.');
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='India Gate';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order, local_tip) VALUES (v_d, v_p, 'Sunset at India Gate', '17:30', 'Monument', 'Free', 3, 'The lawns are great for an evening stroll.');
  END IF;

  -- ========== DELHI LONG WEEKEND ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_delhi AND title='Delhi deep dive — 3 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_delhi, 'Delhi deep dive — 3 days', 'Long weekend', 3, '₹8,000–12,000', 2, 'Three days across Old Delhi, New Delhi, and South Delhi''s monuments.', 'https://images.pexels.com/photos/789750/pexels-photo-789750.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Heritage','Markets','Mughal gardens'], 'Use the metro — it''s the fastest way around Delhi.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Old Delhi') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Red Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Red Fort exploration', '09:00', 'Heritage', '₹80', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Jama Masjid';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Jama Masjid', '11:30', 'Heritage', '₹50', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Chandni Chowk';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Chandni Chowk food crawl', '13:00', 'Food', '₹500', 2);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'New Delhi') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='India Gate';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'India Gate & lawns', '10:00', 'Monument', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Humayun''s Tomb';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Humayun''s Tomb', '13:00', 'Heritage', '₹100', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Lotus Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Lotus Temple', '16:00', 'Landmark', 'Free', 2);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'South Delhi heritage') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Qutub Minar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Qutub Minar', '09:30', 'Heritage', '₹100', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Chandni Chowk';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Shopping & farewell dinner', '18:00', 'Food', '₹800', 1);
  END IF;

  -- ========== DELHI VACAY (Golden Triangle) ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_delhi AND title='Golden Triangle — 5 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_delhi, 'Golden Triangle — 5 days', 'Vacay', 5, '₹20,000–30,000', 2, 'Delhi, Agra, and Jaipur — India''s classic triangle with time to breathe.', 'https://images.pexels.com/photos/19867647/pexels-photo-19867647.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Golden Triangle','Forts','Taj Mahal'], 'Book the Shatabdi Express — it''s faster than driving to Agra.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Delhi arrival') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='India Gate';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'India Gate welcome walk', '17:00', 'Monument', 'Free', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Delhi monuments') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Qutub Minar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Qutub Minar', '09:00', 'Heritage', '₹100', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_delhi AND name='Humayun''s Tomb';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Humayun''s Tomb', '13:00', 'Heritage', '₹100', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Agra day trip') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order, local_tip) VALUES (v_d, 'Taj Mahal at sunrise', '06:00', 'Heritage', '₹250', 0, 'Arrive by 5:45am to beat the queues.');
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Agra Fort', '12:00', 'Heritage', '₹100', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 4, 'Jaipur forts') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Amber Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Amber Fort', '09:30', 'Fort', '₹200', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Hawa Mahal';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Hawa Mahal at sunset', '17:00', 'Monument', '₹100', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 5, 'Jaipur & return') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='City Palace';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'City Palace & Jantar Mantar', '10:00', 'Heritage', '₹300', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Johari Bazaar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Johari Bazaar shopping', '15:00', 'Market', 'Variable', 1);
  END IF;

  -- ========== MUMBAI DAY TRIP ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_mumbai AND title='Mumbai waterfront — 1 day' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_mumbai, 'Mumbai waterfront — 1 day', 'Day trip', 1, '₹1,500–3,000', 2, 'Gateway of India to Marine Drive — the classic Mumbai loop.', 'https://images.pexels.com/photos/37890763/pexels-photo-37890763.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Waterfront','Colonial heritage','Street food'], 'Take the first ferry to Elephanta to avoid the heat and crowds.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Colaba → Marine Drive') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Gateway of India';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Gateway of India', '08:30', 'Monument', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Elephanta Caves';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Elephanta Caves ferry', '09:30', 'Heritage', '₹300', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Colaba Causeway';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Colaba Causeway lunch & shopping', '14:00', 'Market', '₹500', 2);
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Marine Drive';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Sunset at Marine Drive', '18:00', 'Waterfront', 'Free', 3);
  END IF;

  -- ========== MUMBAI LONG WEEKEND ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_mumbai AND title='Mumbai culture crawl — 3 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_mumbai, 'Mumbai culture crawl — 3 days', 'Long weekend', 3, '₹10,000–15,000', 2, 'From Colaba''s galleries to Bandra''s vibe — three sides of Mumbai.', 'https://images.pexels.com/photos/37890763/pexels-photo-37890763.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Art & museums','Bandra cafés','Heritage walks'], 'Take the local train after 11am — off-peak is manageable.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Colaba & Heritage') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Gateway of India';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Gateway of India', '09:00', 'Monument', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Kala Ghoda Art Precinct';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Kala Ghoda galleries', '13:00', 'Culture', '₹200', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Marine Drive';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Marine Drive sunset', '18:00', 'Waterfront', 'Free', 2);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Elephanta & CST') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Elephanta Caves';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Elephanta Caves', '09:30', 'Heritage', '₹300', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Chhatrapati Shivaji Terminus';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'CST architecture walk', '15:00', 'Heritage', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Bandra vibes') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Bandra Worli Sea Link';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Bandra Fort & Sea Link view', '10:00', 'Landmark', 'Free', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Bandra cafés & Hill Road', '13:00', 'Food', '₹600', 1);
  END IF;

  -- ========== MUMBAI VACAY ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_mumbai AND title='Mumbai & Lonavala — 5 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_mumbai, 'Mumbai & Lonavala — 5 days', 'Vacay', 5, '₹18,000–25,000', 3, 'Five days mixing Mumbai''s energy with Lonavala''s monsoon hills.', 'https://images.pexels.com/photos/37890763/pexels-photo-37890763.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['City + hills','Monsoon views','Cafés'], 'Drive to Lonavala early — the Expressway can bottleneck by 10am.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Mumbai arrival') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Marine Drive';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Marine Drive evening walk', '17:00', 'Waterfront', 'Free', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Mumbai sights') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Gateway of India';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Gateway & Elephanta', '09:00', 'Monument', '₹300', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Kala Ghoda Art Precinct';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Kala Ghoda evening', '17:00', 'Culture', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Drive to Lonavala') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Tiger''s Point sunrise', '07:00', 'Viewpoint', 'Free', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Bhushi Dam & waterfalls', '12:00', 'Nature', '₹50', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 4, 'Lonavala treks') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Rajmachi Fort trek', '07:00', 'Trek', '₹100', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Karla Caves', '14:00', 'Heritage', '₹50', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 5, 'Return via Bandra') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_mumbai AND name='Colaba Causeway';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Colaba shopping & farewell', '16:00', 'Market', '₹500', 0);
  END IF;

  -- ========== PUNE DAY TRIP ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_pune AND title='Pune heritage walk — 1 day' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_pune, 'Pune heritage walk — 1 day', 'Day trip', 1, '₹1,000–2,500', 2, 'Forts, temples, and the old Peshwa city in one day.', 'https://images.pexels.com/photos/15623165/pexels-photo-15623165.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Peshwa heritage','Temples','City views'], 'Walk Shaniwar Wada to Parvati Hill — it''s all downhill after the fort.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Old Pune loop') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_pune AND name='Shaniwar Wada';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Shaniwar Wada', '09:00', 'Heritage', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_pune AND name='Dagadusheth Ganpati Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Dagadusheth Temple', '11:00', 'Temple', 'Free', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_pune AND name='Pataleshwar Cave Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Pataleshwar Cave Temple', '13:00', 'Heritage', 'Free', 2);
    SELECT id INTO v_p FROM places WHERE destination_id=v_pune AND name='Parvati Hill';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Sunset at Parvati Hill', '17:30', 'Viewpoint', 'Free', 3);
  END IF;

  -- ========== PUNE LONG WEEKEND ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_pune AND title='Pune & Lonavala — 3 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_pune, 'Pune & Lonavala — 3 days', 'Long weekend', 3, '₹6,000–10,000', 2, 'Pune''s heritage plus a day in the Lonavala hills.', 'https://images.pexels.com/photos/15623165/pexels-photo-15623165.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Forts','Hill station','Caves'], 'Sinhagad Fort is best in the morning — carry water.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Pune city') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_pune AND name='Shaniwar Wada';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Shaniwar Wada', '09:00', 'Heritage', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_pune AND name='Aga Khan Palace';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Aga Khan Palace', '13:00', 'Heritage', '₹100', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_pune AND name='Okayama Friendship Garden';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Okayama Garden stroll', '16:00', 'Park', '₹20', 2);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Sinhagad Fort') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_pune AND name='Sinhagad Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Sinhagad Fort trek', '07:00', 'Fort', '₹100', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Lunch at fort vendors', '12:00', 'Food', '₹200', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Lonavala day') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Tiger''s Point & Lion''s Point', '09:00', 'Viewpoint', 'Free', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Karla Caves', '13:00', 'Heritage', '₹50', 1);
  END IF;

  -- ========== PUNE VACAY ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_pune AND title='Pune, Lavasa & Mahabaleshwar — 5 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_pune, 'Pune, Lavasa & Mahabaleshwar — 5 days', 'Vacay', 5, '₹15,000–22,000', 3, 'Five days from Pune''s heritage to the Western Ghats'' hill stations.', 'https://images.pexels.com/photos/15623165/pexels-photo-15623165.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Hill stations','Strawberry farms','Forts'], 'Mahabaleshwar strawberries are best from December to February.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Pune heritage') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_pune AND name='Shaniwar Wada';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Shaniwar Wada', '09:00', 'Heritage', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_pune AND name='Parvati Hill';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Parvati Hill sunset', '17:30', 'Viewpoint', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Sinhagad') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_pune AND name='Sinhagad Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Sinhagad Fort', '08:00', 'Fort', '₹100', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Lavasa') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Lavasa lakeside promenade', '11:00', 'Lake', 'Free', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Water sports at Warasgaon', '14:00', 'Adventure', '₹500', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 4, 'Mahabaleshwar') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Wilson Point sunrise', '06:30', 'Viewpoint', 'Free', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Mapro Garden & strawberry farm', '12:00', 'Food', '₹300', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 5, 'Pratapgad & return') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Pratapgad Fort', '09:00', 'Fort', '₹50', 0);
  END IF;

  -- ========== NASHIK DAY TRIP ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_nashik AND title='Nashik temples & ghats — 1 day' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_nashik, 'Nashik temples & ghats — 1 day', 'Day trip', 1, '₹800–2,000', 2, 'Panchavati ghats and ancient temples along the Godavari.', 'https://images.pexels.com/photos/23697392/pexels-photo-23697392.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Temples','River ghats','Heritage'], 'Visit Ram Kund early to see the morning aarti.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Temple loop') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='Panchavati';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Panchavati & Ram Kund', '08:00', 'Heritage', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='Trimbakeshwar Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Trimbakeshwar Temple', '12:00', 'Temple', 'Free', 1);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Lunch at a local thali joint', '14:00', 'Food', '₹250', 2);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Sunset at Anjaneri foothills', '17:30', 'Viewpoint', 'Free', 3);
  END IF;

  -- ========== NASHIK LONG WEEKEND ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_nashik AND title='Nashik wine weekend — 3 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_nashik, 'Nashik wine weekend — 3 days', 'Long weekend', 3, '₹8,000–14,000', 2, 'Vineyard tours, tastings, and a temple morning — the perfect Nashik mix.', 'https://images.pexels.com/photos/23697392/pexels-photo-23697392.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Wine tasting','Vineyards','Temples'], 'Book Sula''s tour in advance — weekends sell out.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Wine country') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='Sula Vineyards';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Sula Vineyard tour & tasting', '11:00', 'Winery', '₹600', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='Sula Vineyards Deck';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Sunset dinner on the deck', '18:00', 'Food', '₹1,200', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'More wineries') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='York Winery';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'York Winery tasting', '12:00', 'Winery', '₹500', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Vineyard lunch', '14:00', 'Food', '₹600', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Temple & hills') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='Trimbakeshwar Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Trimbakeshwar Temple', '08:00', 'Temple', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='Anjaneri Hills';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Anjaneri trek', '11:00', 'Trek', 'Free', 1);
  END IF;

  -- ========== NASHIK VACAY ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_nashik AND title='Nashik, Trimbak & Sula — 5 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_nashik, 'Nashik, Trimbak & Sula — 5 days', 'Vacay', 5, '₹15,000–22,000', 2, 'A relaxed wine-and-temple vacation in Maharashtra''s grape country.', 'https://images.pexels.com/photos/23697392/pexels-photo-23697392.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Wine','Trekking','Spiritual'], 'Visit vineyards on weekdays for a quieter experience.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Arrival & Sula') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='Sula Vineyards';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Sula evening tasting', '16:00', 'Winery', '₹600', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'York & vineyards') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='York Winery';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'York Winery', '11:00', 'Winery', '₹500', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Trimbak') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='Trimbakeshwar Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Trimbakeshwar', '08:00', 'Temple', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='Anjaneri Hills';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Anjaneri trek', '11:00', 'Trek', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 4, 'Panchavati') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='Panchavati';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Panchavati ghats', '09:00', 'Heritage', 'Free', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 5, 'Farewell brunch') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nashik AND name='Sula Vineyards Deck';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Sula deck brunch', '11:00', 'Food', '₹800', 0);
  END IF;

  -- ========== NAGPUR DAY TRIP ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_nagpur AND title='Nagpur city highlights — 1 day' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_nagpur, 'Nagpur city highlights — 1 day', 'Day trip', 1, '₹800–2,000', 2, 'Lakes, landmarks, and the Orange City''s best evening spot.', 'https://images.pexels.com/photos/38087491/pexels-photo-38087491.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Lakes','Landmarks','Local food'], 'Futala Lake is best at sunset — grab a bhutta from the stall.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'City loop') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Deeksha Bhoomi';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Deeksha Bhoomi', '09:00', 'Landmark', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Maharajbagh Zoo';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Maharajbagh Zoo & garden', '12:00', 'Park', '₹30', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Ambazari Lake Garden';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Ambazari Lake walk', '15:00', 'Park', 'Free', 2);
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Futala Lake';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Futala Lake sunset', '18:00', 'Lake', 'Free', 3);
  END IF;

  -- ========== NAGPUR LONG WEEKEND ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_nagpur AND title='Nagpur & Ramtek — 3 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_nagpur, 'Nagpur & Ramtek — 3 days', 'Long weekend', 3, '₹6,000–10,000', 2, 'The city plus a day trip to the mythological fort town of Ramtek.', 'https://images.pexels.com/photos/38087491/pexels-photo-38087491.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Fort temple','Lakes','Heritage'], 'Ramtek is a 1-hour drive — hire a cab for the day.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Nagpur city') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Deeksha Bhoomi';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Deeksha Bhoomi', '09:00', 'Landmark', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Futala Lake';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Futala Lake evening', '17:00', 'Lake', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Ramtek day trip') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Ramtek Fort Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Ramtek Fort Temple', '10:00', 'Heritage', '₹50', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Khindsi Lake boating', '14:00', 'Lake', '₹100', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Parks & relaxation') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Ambazari Lake Garden';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Ambazari morning walk', '08:00', 'Park', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Maharajbagh Zoo';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Maharajbagh Zoo', '11:00', 'Park', '₹30', 1);
  END IF;

  -- ========== NAGPUR VACAY ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_nagpur AND title='Nagpur & Pench Tiger Reserve — 5 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_nagpur, 'Nagpur & Pench Tiger Reserve — 5 days', 'Vacay', 5, '₹20,000–35,000', 3, 'Five days combining Nagpur''s heritage with a Pench safari adventure.', 'https://images.pexels.com/photos/38087491/pexels-photo-38087491.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Tiger safari','Heritage','Lakes'], 'Book the Pench safari 30 days ahead — permits sell out fast.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Nagpur arrival') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Deeksha Bhoomi';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Deeksha Bhoomi', '16:00', 'Landmark', 'Free', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Drive to Pench') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Afternoon jungle safari', '15:00', 'Wildlife', '₹2,500', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Pench safaris') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Dawn safari', '06:00', 'Wildlife', '₹2,500', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Evening safari', '15:00', 'Wildlife', '₹2,500', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 4, 'Return to Nagpur') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Futala Lake';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Futala Lake sunset', '17:00', 'Lake', 'Free', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 5, 'Nagpur heritage') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Sitabuldi Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Sitabuldi Fort area', '10:00', 'Fort', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_nagpur AND name='Ambazari Lake Garden';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Ambazari farewell walk', '15:00', 'Park', 'Free', 1);
  END IF;

  -- ========== AMRAVATI DAY TRIP ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_amravati AND title='Amravati temples — 1 day' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_amravati, 'Amravati temples — 1 day', 'Day trip', 1, '₹500–1,500', 2, 'The goddess Amba''s city and its peaceful lakeside spots.', 'https://images.pexels.com/photos/11370871/pexels-photo-11370871.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Temples','Lakes','Local food'], 'Ambadevi Temple is most serene in the early morning.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Temple & lake loop') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Ambadevi Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Ambadevi Temple', '08:00', 'Temple', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Satidham Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Satidham Temple', '11:00', 'Temple', 'Free', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Wadali Talab';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Wadali Talab sunset', '17:30', 'Lake', 'Free', 2);
  END IF;

  -- ========== AMRAVATI LONG WEEKEND ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_amravati AND title='Chikhaldara hills — 3 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_amravati, 'Chikhaldara hills — 3 days', 'Long weekend', 3, '₹6,000–10,000', 2, 'A weekend in Maharashtra''s only coffee-growing hill station.', 'https://images.pexels.com/photos/11370871/pexels-photo-11370871.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Hill station','Coffee','Viewpoints'], 'The road to Chikhaldara is winding — drive carefully in monsoon.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Drive & arrive') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Chikhaldara Hill Station';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Arrive & sunset point', '16:00', 'Hill Station', 'Free', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Melghat safari') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Melghat Tiger Reserve';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Melghat Tiger Reserve safari', '06:00', 'Wildlife', '₹1,500', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Coffee plantation visit', '14:00', 'Plantation', '₹100', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Views & return') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Gugarnal National Park';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Gugarnal National Park walk', '09:00', 'Wildlife', '₹50', 0);
  END IF;

  -- ========== AMRAVATI VACAY ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_amravati AND title='Amravati & Melghat wilderness — 5 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_amravati, 'Amravati & Melghat wilderness — 5 days', 'Vacay', 5, '₹18,000–28,000', 3, 'Five days of temples, tigers, and the Satpura ranges.', 'https://images.pexels.com/photos/11370871/pexels-photo-11370871.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Tigers','Hill station','Temples'], 'Carry binoculars for Melghat — the birdlife is incredible.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Amravati temples') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Ambadevi Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Ambadevi Temple', '09:00', 'Temple', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Wadali Talab';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Wadali Talab', '17:00', 'Lake', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Drive to Chikhaldara') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Chikhaldara Hill Station';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Chikhaldara sunset point', '17:00', 'Hill Station', 'Free', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Melghat safari') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Melghat Tiger Reserve';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Dawn safari', '06:00', 'Wildlife', '₹1,500', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 4, 'Gugarnal & trails') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Gugarnal National Park';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Gugarnal trails', '08:00', 'Wildlife', '₹50', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 5, 'Return') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_amravati AND name='Satidham Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Satidham Temple farewell', '10:00', 'Temple', 'Free', 0);
  END IF;

  -- ========== LUCKNOW DAY TRIP ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_lucknow AND title='Lucknow Nawabi trail — 1 day' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_lucknow, 'Lucknow Nawabi trail — 1 day', 'Day trip', 1, '₹1,000–2,500', 2, 'Imambaras, the Rumi Darwaza, and legendary kebabs.', 'https://images.pexels.com/photos/24416541/pexels-photo-24416541.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Nawabi heritage','Kebabs','Monuments'], 'Tunday kebabs at Akbari Gate are a must — order the mutton.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Old Lucknow loop') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Bara Imambara';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Bara Imambara & Bhulbhulaiya', '09:00', 'Heritage', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Chota Imambara';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Chota Imambara', '12:00', 'Heritage', '₹50', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Rumi Darwaza';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Rumi Darwaza', '15:00', 'Landmark', 'Free', 2);
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Hazratganj Market';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Hazratganj dinner & shopping', '18:00', 'Market', '₹500', 3);
  END IF;

  -- ========== LUCKNOW LONG WEEKEND ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_lucknow AND title='Lucknow heritage weekend — 3 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_lucknow, 'Lucknow heritage weekend — 3 days', 'Long weekend', 3, '₹8,000–12,000', 2, 'Three days of imambaras, kebab trails, and colonial ruins.', 'https://images.pexels.com/photos/24416541/pexels-photo-24416541.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Awadhi cuisine','Heritage','Markets'], 'Take a guided heritage walk through Chowk for hidden gems.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Old Lucknow') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Bara Imambara';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Bara Imambara', '09:00', 'Heritage', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Rumi Darwaza';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Rumi Darwaza & Chowk walk', '14:00', 'Landmark', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Imambaras & market') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Chota Imambara';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Chota Imambara', '09:30', 'Heritage', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Hazratganj Market';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Hazratganj shopping', '15:00', 'Market', '₹500', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Colonial heritage') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='British Residency';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'British Residency', '10:00', 'Heritage', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Ambedkar Memorial Park';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Ambedkar Memorial at dusk', '17:00', 'Park', 'Free', 1);
  END IF;

  -- ========== LUCKNOW VACAY ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_lucknow AND title='Lucknow & Ayodhya — 5 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_lucknow, 'Lucknow & Ayodhya — 5 days', 'Vacay', 5, '₹15,000–25,000', 2, 'Five days of Nawabi heritage and a pilgrimage day to Ayodhya.', 'https://images.pexels.com/photos/24416541/pexels-photo-24416541.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Nawabi heritage','Pilgrimage','Kebab trail'], 'The drive to Ayodhya is ~3 hours — start before 7am.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Old Lucknow') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Bara Imambara';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Bara Imambara', '09:00', 'Heritage', '₹50', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Heritage & food') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Chota Imambara';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Chota Imambara', '10:00', 'Heritage', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Hazratganj Market';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Hazratganj kebab trail', '18:00', 'Food', '₹500', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Ayodhya day trip') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Ram Janmabhoomi temple', '09:00', 'Temple', 'Free', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Sarayu River aarti', '17:00', 'Heritage', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 4, 'Colonial & modern') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='British Residency';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'British Residency', '10:00', 'Heritage', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Ambedkar Memorial Park';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Ambedkar Park', '17:00', 'Park', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 5, 'Farewell') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_lucknow AND name='Rumi Darwaza';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Rumi Darwaza farewell', '10:00', 'Landmark', 'Free', 0);
  END IF;

  -- ========== CHENNAI DAY TRIP ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_chennai AND title='Chennai coastal — 1 day' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_chennai, 'Chennai coastal — 1 day', 'Day trip', 1, '₹1,000–2,500', 2, 'Marina Beach, temples, and filter coffee — the essence of Chennai.', 'https://images.pexels.com/photos/6667281/pexels-photo-6667281.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Beach','Temples','Filter coffee'], 'Marina Beach is best at 6am — the fishermen are returning with their catch.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Coastal loop') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='Marina Beach';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Marina Beach morning', '06:00', 'Beach', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='Kapaleeshwarar Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Kapaleeshwarar Temple', '10:00', 'Temple', 'Free', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='San Thome Basilica';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'San Thome Basilica', '13:00', 'Landmark', 'Free', 2);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Filter coffee at a local café', '15:00', 'Food', '₹100', 3);
  END IF;

  -- ========== CHENNAI LONG WEEKEND ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_chennai AND title='Chennai & Mahabalipuram — 3 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_chennai, 'Chennai & Mahabalipuram — 3 days', 'Long weekend', 3, '₹8,000–12,000', 2, 'Chennai''s temples and a day among Mahabalipuram''s shore temples.', 'https://images.pexels.com/photos/6667281/pexels-photo-6667281.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['UNESCO heritage','Beach','Temples'], 'Mahabalipuram is best on a weekday — fewer tourists at the shore temple.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Chennai city') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='Kapaleeshwarar Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Kapaleeshwarar Temple', '09:00', 'Temple', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='Fort St. George';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Fort St. George', '13:00', 'Heritage', '₹100', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='Marina Beach';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Marina Beach sunset', '18:00', 'Beach', 'Free', 2);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Mahabalipuram') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='Mahabalipuram';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Shore Temple & rock carvings', '09:00', 'Heritage', '₹100', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Mahabalipuram beach lunch', '13:00', 'Food', '₹500', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Museum & farewell') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='Egmore Museum';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Egmore Museum bronzes', '10:00', 'Culture', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='San Thome Basilica';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'San Thome Basilica', '15:00', 'Landmark', 'Free', 1);
  END IF;

  -- ========== CHENNAI VACAY ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_chennai AND title='Chennai, Pondicherry & Mahabalipuram — 5 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_chennai, 'Chennai, Pondicherry & Mahabalipuram — 5 days', 'Vacay', 5, '₹18,000–28,000', 3, 'Five days from Chennai''s coast to Pondicherry''s French Quarter.', 'https://images.pexels.com/photos/6667281/pexels-photo-6667281.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Coast','French Quarter','UNESCO sites'], 'Pondicherry is a 3-hour drive — take the ECR for ocean views.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Chennai arrival') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='Marina Beach';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Marina Beach', '17:00', 'Beach', 'Free', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Mahabalipuram') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='Mahabalipuram';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Shore Temple & carvings', '09:00', 'Heritage', '₹100', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Drive to Pondicherry') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'French Quarter walk', '14:00', 'Culture', 'Free', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Rock Beach promenade', '18:00', 'Beach', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 4, 'Pondicherry day') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Auroville visit', '09:00', 'Culture', 'Free', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Café lunch in White Town', '13:00', 'Food', '₹600', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 5, 'Return via Chennai') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='Kapaleeshwarar Temple';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Kapaleeshwarar Temple', '11:00', 'Temple', 'Free', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_chennai AND name='Egmore Museum';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Egmore Museum', '15:00', 'Culture', '₹50', 1);
  END IF;

  -- ========== HYDERABAD DAY TRIP ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_hyd AND title='Hyderabad old city — 1 day' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_hyd, 'Hyderabad old city — 1 day', 'Day trip', 1, '₹1,000–2,500', 2, 'Charminar, Chowmahalla Palace, and the legendary biryani.', 'https://images.pexels.com/photos/11321242/pexels-photo-11321242.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Nizam heritage','Biryani','Bazaars'], 'Go to Charminar by 8am — the light is soft and the crowds thin.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Old city loop') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Charminar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Charminar', '08:00', 'Monument', '₹100', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Laad Bazaar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Laad Bazaar', '11:00', 'Market', 'Free', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Chowmahalla Palace';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Chowmahalla Palace', '13:00', 'Heritage', '₹80', 2);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Biryani at Paradise or Shadab', '18:00', 'Food', '₹400', 3);
  END IF;

  -- ========== HYDERABAD LONG WEEKEND ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_hyd AND title='Hyderabad Nizam weekend — 3 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_hyd, 'Hyderabad Nizam weekend — 3 days', 'Long weekend', 3, '₹8,000–14,000', 2, 'Three days of forts, palaces, museums, and biryani.', 'https://images.pexels.com/photos/11321242/pexels-photo-11321242.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Golconda Fort','Palaces','Biryani'], 'The Golconda sound-and-light show is at 7pm — worth staying for.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Old city') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Charminar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Charminar & Laad Bazaar', '09:00', 'Monument', '₹100', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Chowmahalla Palace';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Chowmahalla Palace', '13:00', 'Heritage', '₹80', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Golconda & tombs') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Golconda Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Golconda Fort', '09:00', 'Fort', '₹100', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Qutb Shahi Tombs', '14:00', 'Heritage', '₹30', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Museum & lake') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Salar Jung Museum';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Salar Jung Museum', '10:00', 'Museum', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Hussain Sagar Lake';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Hussain Sagar sunset', '17:00', 'Lake', 'Free', 1);
  END IF;

  -- ========== HYDERABAD VACAY ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_hyd AND title='Hyderabad & Warangal — 5 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_hyd, 'Hyderabad & Warangal — 5 days', 'Vacay', 5, '₹16,000–24,000', 3, 'Five days of Nizam heritage and a trip to the Kakatiya ruins at Warangal.', 'https://images.pexels.com/photos/11321242/pexels-photo-11321242.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Kakatiya ruins','Forts','Biryani'], 'Warangal is a 3-hour drive — the 1000-pillar temple is the highlight.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Old city arrival') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Charminar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Charminar evening', '17:00', 'Monument', '₹100', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'Golconda & palaces') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Golconda Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Golconda Fort', '09:00', 'Fort', '₹100', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Chowmahalla Palace';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Chowmahalla Palace', '14:00', 'Heritage', '₹80', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Salar Jung & lake') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Salar Jung Museum';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Salar Jung Museum', '10:00', 'Museum', '₹50', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Hussain Sagar Lake';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Hussain Sagar', '17:00', 'Lake', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 4, 'Warangal day trip') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, '1000-Pillar Temple', '10:00', 'Heritage', '₹50', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Warangal Fort', '14:00', 'Fort', '₹50', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 5, 'Farewell') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_hyd AND name='Laad Bazaar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Laad Bazaar shopping', '11:00', 'Market', 'Free', 0);
  END IF;

  -- ========== JAIPUR DAY TRIP ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_jaipur AND title='Jaipur pink city — 1 day' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_jaipur, 'Jaipur pink city — 1 day', 'Day trip', 1, '₹1,500–3,000', 2, 'Amber Fort, Hawa Mahal, and the City Palace in one royal day.', 'https://images.pexels.com/photos/19867647/pexels-photo-19867647.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Forts','Palaces','Bazaars'], 'Start at Amber Fort by 8am to avoid the bus tours.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Royal loop') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Amber Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Amber Fort', '08:00', 'Fort', '₹200', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Hawa Mahal';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Hawa Mahal', '12:00', 'Monument', '₹100', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='City Palace';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'City Palace & Jantar Mantar', '14:00', 'Heritage', '₹300', 2);
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Johari Bazaar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Johari Bazaar evening', '17:30', 'Market', 'Free', 3);
  END IF;

  -- ========== JAIPUR LONG WEEKEND ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_jaipur AND title='Jaipur forts & palaces — 3 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_jaipur, 'Jaipur forts & palaces — 3 days', 'Long weekend', 3, '₹10,000–16,000', 2, 'Three days across Jaipur''s three forts and its royal bazaars.', 'https://images.pexels.com/photos/19867647/pexels-photo-19867647.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Forts','Sunset views','Rajasthani food'], 'Nahargarh at sunset is the best view in Jaipur — arrive 45 min early.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Amber & old city') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Amber Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Amber Fort', '08:30', 'Fort', '₹200', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Hawa Mahal';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Hawa Mahal', '13:00', 'Monument', '₹100', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'City Palace & astronomy') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='City Palace';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'City Palace', '10:00', 'Heritage', '₹300', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Jantar Mantar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Jantar Mantar', '13:00', 'Heritage', '₹100', 1);
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Johari Bazaar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Johari Bazaar', '17:00', 'Market', 'Free', 2);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Nahargarh sunset') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Nahargarh Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Nahargarh Fort & sunset', '16:00', 'Fort', '₹100', 0);
  END IF;

  -- ========== JAIPUR VACAY ==========
  SELECT id INTO v_t FROM trips WHERE destination_id=v_jaipur AND title='Jaipur, Pushkar & Ranthambore — 5 days' LIMIT 1;
  IF v_t IS NULL THEN
    INSERT INTO trips (user_id, destination_id, title, type, duration_days, budget_text, travelers, blurb, cover_image, status, experiences, local_note)
    VALUES (v_user, v_jaipur, 'Jaipur, Pushkar & Ranthambore — 5 days', 'Vacay', 5, '₹25,000–40,000', 3, 'Five days of Pink City forts, a Pushkar temple town, and a tiger safari.', 'https://images.pexels.com/photos/19867647/pexels-photo-19867647.jpeg?auto=compress&cs=tinysrgb&h=650&w=940', 'published', ARRAY['Tiger safari','Forts','Temple town'], 'Book the Ranthambore safari zone 2-4 for best tiger sightings.')
    RETURNING id INTO v_t;
    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 1, 'Jaipur forts') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Amber Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Amber Fort', '08:30', 'Fort', '₹200', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Nahargarh Fort';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Nahargarh sunset', '17:00', 'Fort', '₹100', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 2, 'City & bazaars') RETURNING id INTO v_d;
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='City Palace';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'City Palace & Jantar Mantar', '10:00', 'Heritage', '₹300', 0);
    SELECT id INTO v_p FROM places WHERE destination_id=v_jaipur AND name='Johari Bazaar';
    INSERT INTO activities (trip_day_id, place_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, v_p, 'Johari Bazaar', '16:00', 'Market', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 3, 'Drive to Ranthambore') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Afternoon safari', '14:00', 'Wildlife', '₹3,000', 0);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 4, 'Ranthambore & Pushkar') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Dawn safari', '06:00', 'Wildlife', '₹3,000', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Pushkar Brahma Temple', '16:00', 'Temple', 'Free', 1);

    INSERT INTO trip_days (trip_id, day_index, label) VALUES (v_t, 5, 'Pushkar & return') RETURNING id INTO v_d;
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Pushkar Lake & ghats', '09:00', 'Heritage', 'Free', 0);
    INSERT INTO activities (trip_day_id, title, start_time, category, cost_text, sort_order) VALUES (v_d, 'Return to Jaipur', '14:00', 'Drive', '₹500', 1);
  END IF;

END $$;
