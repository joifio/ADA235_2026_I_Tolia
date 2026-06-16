/*
Soft Corruption // Generative Ambient Glitch Soundscape

Το έργο είναι ένα generative ambient / glitch ηχοτοπίο στο SuperCollider.
Η σύνθεση χτίζεται σε πολλαπλά layers: ένα smooth drone ως βάση,
τυχαία glitch particles, φασματικοί τόνοι, ψηφιακή ομίχλη,
mid-range συγχορδίες, παρεμβολές χαλασμένου σήματος και granular dust.

Κάθε layer λειτουργεί με τυχαίες παραμέτρους, ώστε το έργο να εξελίσσεται
διαφορετικά κάθε φορά που εκτελείται.
*/

// VIMA 1
(
s.waitForBoot({

    SynthDef(\smoothAmbientDrone, {
        arg out = 0, freq = 95, amp = 0.25;

        var sig;
        var freqs;
        var mods;
        var noise;
        var filter;
        var movement;
        var verb;

        // Βασικές συχνότητες και αρμονικές
        freqs = freq * [1, 1.01, 1.5, 2, 2.01, 3, 4];

        // Πολύ μικρές αργές μεταβολές στο pitch
        mods = LFNoise1.kr([
            0.02, 0.025, 0.03, 0.018, 0.022, 0.015, 0.012
        ]).range(0.995, 1.005);

        // Smooth drone με sine oscillators
        sig = SinOsc.ar(
            freqs * mods,
            0,
            [0.25, 0.22, 0.18, 0.14, 0.12, 0.08, 0.06]
        );

        // Άπλωμα στο stereo
        sig = Splay.ar(sig, 0.7);

        // Απαλό texture για να μην είναι τελείως άδειο
        noise = PinkNoise.ar(0.015 ! 2);
        noise = LPF.ar(noise, 2000);

        sig = sig + noise;

        // Αργό φίλτρο
        filter = LFNoise1.kr(0.025).range(1200, 3500);
        sig = LPF.ar(sig, filter);

        // Αργή αναπνοή στην ένταση
        movement = LFNoise1.kr(0.02).range(0.75, 1.0);
        sig = sig * movement;

        // Reverb μέσα στο ίδιο synth
        verb = FreeVerb2.ar(
            sig[0],
            sig[1],
            0.45,
            0.95,
            0.35
        );

        sig = (sig * 0.6) + (verb * 0.7);

        // Καθαρισμός και προστασία έντασης
        sig = LeakDC.ar(sig);
        sig = Limiter.ar(sig, 0.8);

        Out.ar(out, sig * amp);

    }).add;

    s.sync;

    ~drone = Synth(\smoothAmbientDrone, [
        \freq, 95,
        \amp, 0.3
    ]);

});
)


// VIMA 2

(
s.waitForBoot({

    SynthDef(\softGlitch, {
        arg out = 0, freq = 1200, amp = 0.03, pan = 0, dur = 0.08;

        var env;
        var tone;
        var noise;
        var sig;
        var verb;

        // Σύντομο envelope για μικρό glitch συμβάν
        env = EnvGen.kr(
            Env.perc(0.001, dur, curve: -4),
            doneAction: 2
        );

        // Μικρή τονική σπίθα
        tone = SinOsc.ar(
            freq * LFNoise1.kr(20).range(0.97, 1.03),
            0,
            0.5
        );

        // Ψηφιακός θόρυβος, φιλτραρισμένος γύρω από τη συχνότητα
        noise = BPF.ar(
            WhiteNoise.ar(0.7),
            freq,
            0.2
        );

        sig = (tone + noise) * env;

        // Κόβουμε πολύ χαμηλές συχνότητες για να μη μπουκώνει το drone
        sig = HPF.ar(sig, 250);

        // Stereo θέση
        sig = Pan2.ar(sig, pan);

        // Μικρό reverb για να μπαίνει μέσα στον χώρο
        verb = FreeVerb2.ar(
            sig[0],
            sig[1],
            0.35,
            0.85,
            0.5
        );

        sig = (sig * 0.7) + (verb * 0.5);

        sig = Limiter.ar(sig, 0.6);

        Out.ar(out, sig * amp);

    }).add;


    s.sync;

    // Generative διαδικασία: δημιουργεί glitches σε τυχαία χρονικά διαστήματα
    Tdef(\glitchParticles, {

        loop {

            Synth(\softGlitch, [
                \freq, exprand(500, 6500),
                \amp, exprand(0.015, 0.06),
                \pan, rrand(-0.9, 0.9),
                \dur, exprand(0.015, 0.16)
            ]);

            // Χρόνος μέχρι το επόμενο glitch
            exprand(0.35, 3.2).wait;
        };

    }).play;

});
)


// VIMA 3


(
s.waitForBoot({

    SynthDef(\ghostTone, {
        arg out = 0, freq = 220, amp = 0.04, pan = 0, dur = 4;

        var env;
        var sig;
        var shimmer;
        var verb;

        // Αργό envelope, για να μπαίνει και να φεύγει μαλακά
        env = EnvGen.kr(
            Env.linen(0.8, dur, 2.5, curve: -3),
            doneAction: 2
        );

        // Μαλακός βασικός τόνος
        sig = SinOsc.ar(freq, 0, 0.5);

        // Λίγες ήπιες αρμονικές για περισσότερο σώμα
        shimmer = Mix([
            SinOsc.ar(freq * 1.5, 0, 0.18),
            SinOsc.ar(freq * 2.01, 0, 0.12),
            SinOsc.ar(freq * 3.02, 0, 0.06)
        ]);

        sig = sig + shimmer;

        // Πολύ αργή κίνηση στο φίλτρο
        sig = LPF.ar(
            sig,
            LFNoise1.kr(0.04).range(900, 2800)
        );

        sig = sig * env;

        // Stereo θέση
        sig = Pan2.ar(sig, pan);

        // Μεγάλο reverb για ατμόσφαιρα
        verb = FreeVerb2.ar(
            sig[0],
            sig[1],
            0.55,
            0.98,
            0.4
        );

        sig = (sig * 0.4) + (verb * 0.8);

        sig = LeakDC.ar(sig);
        sig = Limiter.ar(sig, 0.7);

        Out.ar(out, sig * amp);

    }).add;


    s.sync;

    // Generative layer με αραιούς φασματικούς τόνους
    Tdef(\ghostTones, {

        var notes;

        // Περιορισμένες νότες για να υπάρχει συνοχή στο ηχοτοπίο
        notes = [48, 51, 55, 58, 60, 63, 67, 70];

        loop {

            Synth(\ghostTone, [
                \freq, notes.choose.midicps * [0.5, 1, 2].choose,
                \amp, exprand(0.006, 0.02),
                \pan, rrand(-0.8, 0.8),
                \dur, exprand(2.5, 7.0)
            ]);

            // Αραιή εμφάνιση
            exprand(4.0, 11.0).wait;
        };

    }).play;

});
)

// VIMA 4

(
s.waitForBoot({

    SynthDef(\dataMist2, {
        arg out = 0, amp = 0.09;

        var baseNoise;
        var filteredNoise;
        var crackles;
        var digitalBits;
        var pulses;
        var sig;
        var filterFreq;
        var verb;
        var panMove;

        // Πιο φωτεινή βάση θορύβου
        baseNoise = WhiteNoise.ar(0.25 ! 2);

        // Κινούμενο band-pass φίλτρο για αίσθηση ψηφιακής ομίχλης
        filterFreq = LFNoise1.kr(0.12 ! 2).exprange(1000, 7000);
        filteredNoise = BPF.ar(baseNoise, filterFreq, 0.12);

        // Μικρά crackles, πιο αισθητά από πριν
        crackles = Dust2.ar(
            LFNoise1.kr(0.15 ! 2).range(8, 35)
        );

        crackles = Decay2.ar(crackles, 0.002, 0.04);
        crackles = BPF.ar(crackles, LFNoise1.kr(2 ! 2).exprange(1500, 9000), 0.3);
        crackles = crackles * 0.18;

        // Sample-hold ψηφιακή υφή
        digitalBits = Latch.ar(
            filteredNoise,
            Impulse.ar(LFNoise1.kr(0.08 ! 2).exprange(600, 5000))
        );

        // Πολύ μικρά τυχαία pulses σαν χαλασμένο σήμα
        pulses = Impulse.ar(
            LFNoise1.kr(0.2 ! 2).exprange(1, 12)
        );

        pulses = Decay2.ar(pulses, 0.001, 0.03);
        pulses = SinOsc.ar(
            LFNoise1.kr(3 ! 2).exprange(900, 5000),
            0,
            pulses * 0.08
        );

        // Μίξη όλων
        sig = (filteredNoise * 0.55) + (digitalBits * 0.35) + crackles + pulses;

        // Κρατάμε το layer πάνω από το drone, για να μη χαθεί στις χαμηλές
        sig = HPF.ar(sig, 800);
        sig = LPF.ar(sig, 9000);

        // Αργή stereo κίνηση
        panMove = LFNoise1.kr(0.05).range(-0.4, 0.4);
        sig = Balance2.ar(sig[0], sig[1], panMove);

        // Reverb για να μην ακούγεται τελείως στεγνό
        verb = FreeVerb2.ar(
            sig[0],
            sig[1],
            0.35,
            0.8,
            0.45
        );

        sig = (sig * 0.75) + (verb * 0.45);

        sig = LeakDC.ar(sig);
        sig = Limiter.ar(sig, 0.7);

        Out.ar(out, sig * amp);

    }).add;

    s.sync;

    ~mist = Synth(\dataMist2, [
        \amp, 0.09
    ]);

});
)

// VIMA 5

(
s.waitForBoot({

    SynthDef(\midChordDrone, {
        arg out = 0,
        freq1 = 220, freq2 = 277, freq3 = 330, freq4 = 415,
        amp = 0.045, dur = 14;

        var freqs;
        var detune;
        var sig;
        var env;
        var filter;
        var movement;
        var verb;

        // Οι τέσσερις νότες της συγχορδίας
        freqs = [freq1, freq2, freq3, freq4];

        // Πολύ μικρό detune για οργανική αστάθεια
        detune = LFNoise1.kr([0.03, 0.027, 0.021, 0.018]).range(0.997, 1.003);

        // Smooth αρμονικό σώμα με sine waves
        sig = SinOsc.ar(
            freqs * detune,
            0,
            [0.26, 0.22, 0.2, 0.16]
        );

        // Πολύ χαμηλές άνω αρμονικές για να ακούγεται λίγο πιο γεμάτο
        sig = sig + SinOsc.ar(
            (freqs * 2.001) * detune,
            0,
            [0.04, 0.035, 0.03, 0.025]
        );

        // Άπλωμα στο stereo
        sig = Splay.ar(sig, 0.8);

        // Μεγάλο fade in / sustain / fade out
        env = EnvGen.kr(
            Env.linen(5, dur, 9, curve: -3),
            doneAction: 2
        );

        // Αργό φίλτρο για να κινείται απαλά
        filter = LFNoise1.kr(0.025).range(900, 2800);
        sig = LPF.ar(sig, filter);

        // Αργή κίνηση έντασης
        movement = LFNoise1.kr(0.02).range(0.55, 1.0);

        sig = sig * env * movement;

        // Μεγάλο reverb
        verb = FreeVerb2.ar(
            sig[0],
            sig[1],
            0.5,
            0.97,
            0.45
        );

        sig = (sig * 0.45) + (verb * 0.85);

        sig = LeakDC.ar(sig);
        sig = Limiter.ar(sig, 0.7);

        Out.ar(out, sig * amp);

    }).add;


    s.sync;

    Tdef(\midChords, {

        var chords;
        var chord;

        // Μικρή δεξαμενή από ατμοσφαιρικές συγχορδίες
        // Είναι όλες σε κοντινό χρωματικό/ambient χώρο για να μην ακούγονται σαν τραγούδι
        chords = [
            [52, 55, 59, 62],
            [50, 55, 58, 62],
            [48, 55, 60, 63],
            [51, 55, 60, 67],
            [47, 54, 58, 62],
            [52, 58, 60, 65]
        ];

        loop {

            chord = chords.choose;

            Synth(\midChordDrone, [
                \freq1, chord[0].midicps,
                \freq2, chord[1].midicps,
                \freq3, chord[2].midicps,
                \freq4, chord[3].midicps,
                \amp, exprand(0.025, 0.055),
                \dur, exprand(10.0, 22.0)
            ]);

            // Οι συγχορδίες επικαλύπτονται λίγο μεταξύ τους
            exprand(9.0, 18.0).wait;
        };

    }).play;

});
)

// VIMA 6

(
s.waitForBoot({

    SynthDef(\signalTear, {
        arg out = 0, amp = 0.06, dur = 3.0, pan = 0, center = 2500;

        var env;
        var noise;
        var digital;
        var tone;
        var sig;
        var sweep;
        var delay;
        var verb;

        // Αργό envelope, σαν το σήμα να ανοίγει και να κλείνει
        env = EnvGen.kr(
            Env.linen(0.4, dur, 1.2, curve: -4),
            doneAction: 2
        );

        // Θόρυβος ως βάση της παρεμβολής
        noise = WhiteNoise.ar(0.5);

// Κινούμενο φίλτρο
sweep = XLine.kr(
    center * Rand.ir(0.5, 0.9),
    center * Rand.ir(1.1, 2.2),
    dur + 1.2
);

        noise = BPF.ar(noise, sweep, 0.18);

        // Sample-hold για ψηφιακή αίσθηση
        digital = Latch.ar(
            noise,
            Impulse.ar(LFNoise1.kr(0.4).exprange(700, 5000))
        );

        // Ένας αχνός τόνος μέσα στο noise
        tone = SinOsc.ar(
            center * LFNoise1.kr(2).range(0.7, 1.4),
            0,
            0.08
        );

        sig = (noise * 0.5) + (digital * 0.6) + tone;

        // Κόβουμε χαμηλές για να μην συγκρουστεί με το drone
        sig = HPF.ar(sig, 600);
        sig = LPF.ar(sig, 8000);

        // Μικρό delay σαν σπασμένη αντήχηση
        delay = CombC.ar(
            sig,
            0.3,
            LFNoise1.kr(0.7).range(0.04, 0.18),
            2.5
        );

        sig = (sig * 0.7) + (delay * 0.35);

        sig = sig * env;

        sig = Pan2.ar(sig, pan);

        // Reverb για να κολλήσει με τον υπόλοιπο χώρο
        verb = FreeVerb2.ar(
            sig[0],
            sig[1],
            0.45,
            0.9,
            0.5
        );

        sig = (sig * 0.6) + (verb * 0.55);

        sig = LeakDC.ar(sig);
        sig = Limiter.ar(sig, 0.7);

        Out.ar(out, sig * amp);

    }).add;


    s.sync;

    Tdef(\signalTears, {

        loop {

            Synth(\signalTear, [
                \amp, exprand(0.025, 0.075),
                \dur, exprand(1.5, 5.5),
                \pan, rrand(-0.8, 0.8),
                \center, exprand(900, 5200)
            ]);

            // Αραιή εμφάνιση
            exprand(8.0, 22.0).wait;
        };

    }).play;

});
)

// VIMA 7

(
s.waitForBoot({

    SynthDef(\granularDust, {
        arg out = 0, amp = 0.04, dur = 8,
        density = 14, low = 600, high = 6000;

        var trig;
        var grainEnv;
        var freq;
        var tones;
        var noise;
        var sig;
        var ampEnv;
        var filterMove;
        var verb;

        // Τυχαία triggers για μικρούς κόκκους ήχου
        trig = Dust2.ar(density ! 2);

        // Πολύ μικρό envelope για κάθε grain
        grainEnv = Decay2.ar(
            trig,
            0.003,
            LFNoise1.kr(0.4 ! 2).range(0.02, 0.12)
        );

        // Κάθε grain παίρνει τυχαία συχνότητα
        freq = TExpRand.ar(low, high, trig);

        // Μικρά sine grains
        tones = SinOsc.ar(freq, 0, grainEnv);

        // Λίγος θόρυβος μαζί με τα grains
        noise = BPF.ar(
            WhiteNoise.ar(0.12 ! 2),
            freq,
            0.18
        ) * grainEnv * 0.5;

        sig = tones + noise;

        // Κρατάμε το layer πιο ψηλά από το βασικό drone
        sig = HPF.ar(sig, 500);

        // Κινούμενο φίλτρο
        filterMove = LFNoise1.kr(0.06 ! 2).exprange(1200, 7500);
        sig = LPF.ar(sig, filterMove);

        // Μεγάλο fade in/out για να μπαίνει σαν σύννεφο
        ampEnv = EnvGen.kr(
            Env.linen(2, dur, 5, curve: -4),
            doneAction: 2
        );

        sig = sig * ampEnv;

        // Reverb για ατμόσφαιρα
        verb = FreeVerb2.ar(
            sig[0],
            sig[1],
            0.45,
            0.93,
            0.5
        );

        sig = (sig * 0.55) + (verb * 0.65);

        sig = LeakDC.ar(sig);
        sig = Limiter.ar(sig, 0.6);

        Out.ar(out, sig * amp);

    }).add;


    s.sync;

    Tdef(\granularDustLayer, {

        loop {

            Synth(\granularDust, [
                \amp, exprand(0.012, 0.045),
                \dur, exprand(5.0, 14.0),
                \density, exprand(6, 22),
                \low, exprand(400, 1200),
                \high, exprand(3000, 9000)
            ]);

            // Αραιή εμφάνιση νεφών από grains
            exprand(10.0, 24.0).wait;
        };

    }).play;

});
)

// STOP ALL LAYERS

(
Tdef(\glitchParticles).stop;
Tdef(\ghostTones).stop;
Tdef(\midChords).stop;
Tdef(\signalTears).stop;
Tdef(\granularDustLayer).stop;

if(~drone.notNil) { ~drone.free; };
if(~mist.notNil) { ~mist.free; };
)
