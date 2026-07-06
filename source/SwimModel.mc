// SwimModel.mc - v5.3
// Modèle de données principal + détection des longueurs via accéléromètre
// Correction : ajout de poolLength obligatoire pour SPORT_SWIMMING + SUB_SPORT_LAP_SWIMMING
// Compatible Connect IQ SDK 9.1.0

import Toybox.Lang;
import Toybox.Sensor;
import Toybox.System;
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.FitContributor;
import Toybox.Math;
import Toybox.Time;
import Toybox.Application;
import Toybox.WatchUi;

class SwimModel {

    static const POOL_LENGTHS as Array<Number> = [8, 10, 15, 20, 25, 33, 50] as Array<Number>;
    static const DEFAULT_POOL_LENGTH_IDX as Number = 4;

    enum ActivityState {
        STATE_SETUP,
        STATE_READY,
        STATE_ACTIVE,
        STATE_PAUSED,
        STATE_FINISHED
    }

    private const ACCEL_SAMPLE_RATE         as Number = 25;
    private const DEFAULT_SWIM_THRESHOLD    as Float  = 1.5f;
    private const DEFAULT_TURN_THRESHOLD    as Float  = 1.5f;
    private const DEFAULT_MIN_SWIM_TIME_MS  as Number = 500;
    private const DEFAULT_MIN_LAP_TIME_MS   as Number = 1200;
    private const FAST_SMOOTHING            as Float  = 0.3f;
    private const BASELINE_SMOOTHING        as Float  = 0.05f;

    static const SWIM_THRESHOLD_MIN  as Float = 0.5f;
    static const SWIM_THRESHOLD_MAX  as Float = 3.0f;
    static const SWIM_THRESHOLD_STEP as Float = 0.1f;
    static const TURN_THRESHOLD_MIN  as Float = 0.3f;
    static const TURN_THRESHOLD_MAX  as Float = 1.5f;
    static const TURN_THRESHOLD_STEP as Float = 0.1f;
    static const MIN_SWIM_TIME_MIN  as Number = 500;
    static const MIN_SWIM_TIME_MAX  as Number = 5000;
    static const MIN_SWIM_TIME_STEP as Number = 250;
    static const MIN_LAP_TIME_MIN  as Number = 1000;
    static const MIN_LAP_TIME_MAX  as Number = 10000;
    static const MIN_LAP_TIME_STEP as Number = 250;

    var state                 as ActivityState = STATE_SETUP;
    var poolLengthIdx         as Number  = DEFAULT_POOL_LENGTH_IDX;
    var lapCount              as Number  = 0;
    var totalDistanceM        as Number  = 0;
    var elapsedMs             as Number  = 0;
    var currentPaceSecPer100m as Number  = 0;
    var isRecording           as Boolean = false;

    var swimThreshold  as Float  = DEFAULT_SWIM_THRESHOLD;
    var turnThreshold  as Float  = DEFAULT_TURN_THRESHOLD;
    var minSwimTimeMs  as Number = DEFAULT_MIN_SWIM_TIME_MS;
    var minLapTimeMs   as Number = DEFAULT_MIN_LAP_TIME_MS;

    private var _session        as ActivityRecording.Session?;
    private var _startTime      as Time.Moment?;
    private var _pauseStartTime as Time.Moment?;
    private var _totalPausedMs  as Number  = 0;
    private var _fastAccel      as Float   = 0.0f;
    private var _baselineAccel  as Float   = 0.0f;
    private var _peakDetected   as Boolean = false;
    private var _lastPeakMs     as Number  = 0;
    private var _isSwimming     as Boolean = false;
    private var _swimStartMs    as Number  = 0;
    private var _lapTimes       as Array<Number>;
    private var _lastLapStartMs as Number  = 0;

    var strokeCountPeaks    as Number = 0;
    var strokeCountEstimate as Number = 0;
    private var _lastStrokeEstimateMs as Number = 0;
    private const STROKE_ESTIMATE_INTERVAL_MS as Number = 1500;

    var debugAmpX        as Float = 0.0f;
    var debugAmpY        as Float = 0.0f;
    var debugAmpZ        as Float = 0.0f;
    var debugAmpMax      as Float = 0.0f;
    var debugFastAccel   as Float = 0.0f;
    var debugBaseline    as Float = 0.0f;
    var debugRatio       as Float = 0.0f;
    var debugMaxAmpEver  as Float = 0.0f;
    var debugMinAmpEver  as Float = 999.0f;

    private var _distanceField    as FitContributor.Field?;
    private var _lapDistanceField as FitContributor.Field?;
    private var _debugAmpField    as FitContributor.Field?;
    private var _debugRatioField  as FitContributor.Field?;
    private var _debugTurnField   as FitContributor.Field?;

    function initialize() {
        _lapTimes = [] as Array<Number>;
        var savedIdx = Application.Storage.getValue("poolLengthIdx");
        if (savedIdx != null) {
            poolLengthIdx = savedIdx as Number;
        }
        _loadDetectionSettings();
    }

    private function _loadDetectionSettings() as Void {
        var v;
        v = Application.Storage.getValue("swimThreshold");
        swimThreshold = (v != null) ? (v as Float) : DEFAULT_SWIM_THRESHOLD;
        v = Application.Storage.getValue("turnThreshold");
        turnThreshold = (v != null) ? (v as Float) : DEFAULT_TURN_THRESHOLD;
        v = Application.Storage.getValue("minSwimTimeMs");
        minSwimTimeMs = (v != null) ? (v as Number) : DEFAULT_MIN_SWIM_TIME_MS;
        v = Application.Storage.getValue("minLapTimeMs");
        minLapTimeMs = (v != null) ? (v as Number) : DEFAULT_MIN_LAP_TIME_MS;
    }

    function setSwimThreshold(val as Float) as Void {
        swimThreshold = val;
        Application.Storage.setValue("swimThreshold", val);
    }

    function setTurnThreshold(val as Float) as Void {
        turnThreshold = val;
        Application.Storage.setValue("turnThreshold", val);
    }

    function setMinSwimTimeMs(val as Number) as Void {
        minSwimTimeMs = val;
        Application.Storage.setValue("minSwimTimeMs", val);
    }

    function setMinLapTimeMs(val as Number) as Void {
        minLapTimeMs = val;
        Application.Storage.setValue("minLapTimeMs", val);
    }

    function resetDetectionSettingsToDefaults() as Void {
        setSwimThreshold(DEFAULT_SWIM_THRESHOLD);
        setTurnThreshold(DEFAULT_TURN_THRESHOLD);
        setMinSwimTimeMs(DEFAULT_MIN_SWIM_TIME_MS);
        setMinLapTimeMs(DEFAULT_MIN_LAP_TIME_MS);
    }

    function getPoolLength() as Number {
        return POOL_LENGTHS[poolLengthIdx];
    }

    function getFormattedPace() as String {
        if (currentPaceSecPer100m <= 0) { return "--:--"; }
        var minutes = currentPaceSecPer100m / 60;
        var seconds = currentPaceSecPer100m % 60;
        return minutes.format("%d") + ":" + seconds.format("%02d");
    }

    function getFormattedDuration() as String {
        updateElapsedTime();
        var totalSec = elapsedMs / 1000;
        var hours    = totalSec / 3600;
        var minutes  = (totalSec % 3600) / 60;
        var seconds  = totalSec % 60;
        if (hours > 0) {
            return hours.format("%d") + ":" + minutes.format("%02d") + ":" + seconds.format("%02d");
        }
        return minutes.format("%02d") + ":" + seconds.format("%02d");
    }

    function getFormattedDistance() as String {
        if (totalDistanceM >= 1000) {
            var km = totalDistanceM / 1000.0f;
            return km.format("%.2f") + " km";
        }
        return totalDistanceM.format("%d") + " m";
    }

    function startActivity() as Void {
        if (state != STATE_READY && state != STATE_SETUP) { return; }

        var options = {
            :name      => "Natation Piscine",
            :sport     => Activity.SPORT_SWIMMING,
            :subSport  => Activity.SUB_SPORT_LAP_SWIMMING,
            :poolLength => getPoolLength()  // FIX: Champ obligatoire pour la natation
        };
        _session = ActivityRecording.createSession(options);

        if (_session == null) {
            state = STATE_FINISHED;
            return;
        }

        _distanceField = _session.createField(
            "pool_distance_m", 0, FitContributor.DATA_TYPE_FLOAT,
            { :mesgType => FitContributor.MESG_TYPE_SESSION, :units => "meters" }
        );
        _lapDistanceField = _session.createField(
            "lap_distance_m", 4, FitContributor.DATA_TYPE_FLOAT,
            { :mesgType => FitContributor.MESG_TYPE_LAP, :units => "meters" }
        );
        _debugAmpField = _session.createField(
            "debug_amp_max", 1, FitContributor.DATA_TYPE_FLOAT,
            { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "g" }
        );
        _debugRatioField = _session.createField(
            "debug_ratio", 2, FitContributor.DATA_TYPE_FLOAT,
            { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "x" }
        );
        _debugTurnField = _session.createField(
            "debug_turn_detected", 3, FitContributor.DATA_TYPE_UINT8,
            { :mesgType => FitContributor.MESG_TYPE_RECORD, :units => "bool" }
        );

        _session.start();
        _startTime      = Time.now();
        _totalPausedMs  = 0;
        lapCount        = 0;
        totalDistanceM  = 0;
        elapsedMs       = 0;
        _lastLapStartMs = 0;
        _lapTimes       = [] as Array<Number>;
        _fastAccel      = 0.0f;
        _baselineAccel  = 0.0f;
        _peakDetected   = false;
        _lastPeakMs     = 0;
        _isSwimming     = false;
        _swimStartMs    = 0;
        strokeCountPeaks    = 0;
        strokeCountEstimate = 0;
        _lastStrokeEstimateMs = 0;
        state           = STATE_ACTIVE;
        isRecording     = true;

        _loadDetectionSettings();
        
        // Désenregistrer un éventuel listener existant avant d'en créer un nouveau
        Sensor.unregisterSensorDataListener();
        _startSensors();
        WatchUi.requestUpdate();
    }

    function pauseActivity() as Void {
        if (state != STATE_ACTIVE) { return; }
        state           = STATE_PAUSED;
        _pauseStartTime = Time.now();
        updateElapsedTime();
        Sensor.unregisterSensorDataListener();
        WatchUi.requestUpdate();
    }

    function resumeActivity() as Void {
        if (state != STATE_PAUSED) { return; }
        if (_pauseStartTime != null) {
            var pauseDuration = Time.now().subtract(_pauseStartTime);
            _totalPausedMs += pauseDuration.value() * 1000;
        }
        _pauseStartTime = null;
        state = STATE_ACTIVE;
        
        // Désenregistrer avant de réenregistrer
        Sensor.unregisterSensorDataListener();
        _startSensors();
        WatchUi.requestUpdate();
    }

    function finishActivity() as Void {
        if (state == STATE_ACTIVE || state == STATE_PAUSED) {
            updateElapsedTime();
            Sensor.unregisterSensorDataListener();
            if (_distanceField != null) {
                _distanceField.setData(totalDistanceM.toFloat());
            }
            if (_session != null) {
                _session.stop();
                _session.save();
                _session          = null;
                _distanceField    = null;
                _lapDistanceField = null;
                _debugAmpField    = null;
                _debugRatioField  = null;
                _debugTurnField   = null;
            }
        }
        isRecording = false;
        state = STATE_FINISHED;
        WatchUi.requestUpdate();
    }

    function discardActivity() as Void {
        if (state == STATE_ACTIVE || state == STATE_PAUSED) {
            Sensor.unregisterSensorDataListener();
            if (_session != null) {
                if (_session.isRecording()) {
                    _session.stop();
                }
                _session.discard();
                _session          = null;
                _distanceField    = null;
                _lapDistanceField = null;
                _debugAmpField    = null;
                _debugRatioField  = null;
                _debugTurnField   = null;
            }
        }
        isRecording = false;
        state = STATE_FINISHED;
        WatchUi.requestUpdate();
    }

    function onStop() as Void {
        if (state == STATE_ACTIVE || state == STATE_PAUSED) {
            finishActivity();
        }
    }

    function addLapManual() as Void {
        if (state != STATE_ACTIVE) { return; }
        _recordLap();
    }

    private function _startSensors() as Void {
        var options = {
            :period => 1,
            :accelerometer => {
                :enabled => true,
                :sampleRate => ACCEL_SAMPLE_RATE
            }
        };
        Sensor.registerSensorDataListener(method(:onSensorData), options);
    }

    function onSensorData(sensorData as Sensor.SensorData) as Void {
        if (state != STATE_ACTIVE) { return; }
        
        // Vérification de base
        if (sensorData == null) { return; }

        var accelData = sensorData.accelerometerData;
        
        if (accelData == null) { return; }

        var ampX = _getMaxAmplitude(accelData.x) / 1000.0f;
        var ampY = _getMaxAmplitude(accelData.y) / 1000.0f;
        var ampZ = _getMaxAmplitude(accelData.z) / 1000.0f;

        var amplitude = ampX;
        if (ampY > amplitude) { amplitude = ampY; }
        if (ampZ > amplitude) { amplitude = ampZ; }

        debugAmpX   = ampX;
        debugAmpY   = ampY;
        debugAmpZ   = ampZ;
        debugAmpMax = amplitude;
        if (amplitude > debugMaxAmpEver) { debugMaxAmpEver = amplitude; }
        if (amplitude < debugMinAmpEver) { debugMinAmpEver = amplitude; }

        _fastAccel     = _fastAccel     * (1.0f - FAST_SMOOTHING)     + amplitude * FAST_SMOOTHING;
        _baselineAccel = _baselineAccel * (1.0f - BASELINE_SMOOTHING) + amplitude * BASELINE_SMOOTHING;
        debugFastAccel = _fastAccel;
        debugBaseline  = _baselineAccel;
        debugRatio     = (_baselineAccel > 0.01f) ? (_fastAccel / _baselineAccel) : 0.0f;

        updateElapsedTime();

        if (_debugAmpField != null) {
            _debugAmpField.setData(amplitude);
        }
        if (_debugRatioField != null) {
            _debugRatioField.setData(debugRatio);
        }
        if (_debugTurnField != null) {
            _debugTurnField.setData(0);
        }

        if (elapsedMs - _lastStrokeEstimateMs >= STROKE_ESTIMATE_INTERVAL_MS) {
            _lastStrokeEstimateMs = elapsedMs;
            strokeCountEstimate += 1;
        }

        if (elapsedMs < 2000) { return; }

        if (!_isSwimming) {
            if (_fastAccel >= swimThreshold) {
                if (_swimStartMs == 0) {
                    _swimStartMs = elapsedMs;
                } else if (elapsedMs - _swimStartMs >= minSwimTimeMs) {
                    _isSwimming = true;
                }
            } else {
                _swimStartMs = 0;
            }
        } else {
            // En nage active — compter les mouvements de bras (pics)
            if (!_peakDetected && amplitude > swimThreshold * 1.3f) {
                _peakDetected = true;
                strokeCountPeaks += 1;
            } else if (_peakDetected && amplitude < swimThreshold) {
                _peakDetected = false;
            }

            // Détection de virage par creux d'amplitude (sans gyroscope)
            if (_fastAccel < turnThreshold) {
                _isSwimming   = false;
                _swimStartMs  = 0;
                _peakDetected = false;

                var timeSinceLastLap = elapsedMs - _lastPeakMs;
                if (timeSinceLastLap >= minLapTimeMs) {
                    _lastPeakMs = elapsedMs;
                    if (_debugTurnField != null) {
                        _debugTurnField.setData(1);
                    }
                    _recordLap();
                }
            }
        }
    }

    private function _getMaxAmplitude(samples as Array<Number>?) as Float {
        if (samples == null || samples.size() == 0) { return 0.0f; }
        var maxVal = samples[0].toFloat();
        var minVal = samples[0].toFloat();
        for (var i = 1; i < samples.size(); i++) {
            var v = samples[i].toFloat();
            if (v > maxVal) { maxVal = v; }
            if (v < minVal) { minVal = v; }
        }
        return maxVal - minVal;
    }

    private function _recordLap() as Void {
        lapCount += 1;
        totalDistanceM = lapCount * getPoolLength();

        if (_distanceField != null) {
            _distanceField.setData(totalDistanceM.toFloat());
        }
        if (_lapDistanceField != null) {
            _lapDistanceField.setData(getPoolLength().toFloat());
        }
        if (_session != null) {
            _session.addLap();
        }

        var nowMs = elapsedMs;
        if (_lastLapStartMs > 0) {
            var lapDurationMs = nowMs - _lastLapStartMs;
            if (lapDurationMs > 0) {
                var secPerLength = lapDurationMs / 1000.0f;
                var secPer100m   = (secPerLength / getPoolLength()) * 100.0f;
                
                // Protection : s'assurer que _lapTimes existe
                if (_lapTimes == null) {
                    _lapTimes = [] as Array<Number>;
                }
                
                _lapTimes.add(secPer100m.toNumber());
                if (_lapTimes.size() > 3) {
                    _lapTimes = _lapTimes.slice(1, null);
                }
                var sum = 0;
                for (var i = 0; i < _lapTimes.size(); i++) {
                    sum += _lapTimes[i];
                }
                currentPaceSecPer100m = (sum / _lapTimes.size()).toNumber();
            }
        }
        _lastLapStartMs = nowMs;
        WatchUi.requestUpdate();
    }

    function updateElapsedTime() as Void {
        if (_startTime == null || state == STATE_SETUP
            || state == STATE_READY || state == STATE_FINISHED) {
            return;
        }
        var now      = Time.now();
        var totalMs  = now.subtract(_startTime).value() * 1000;
        var activeMs = totalMs - _totalPausedMs;
        if (state == STATE_PAUSED && _pauseStartTime != null) {
            var currentPause = now.subtract(_pauseStartTime).value() * 1000;
            activeMs -= currentPause;
        }
        if (activeMs > 0) {
            elapsedMs = activeMs;
        }
    }

    function increasePoolLength() as Void {
        if (poolLengthIdx < POOL_LENGTHS.size() - 1) {
            poolLengthIdx++;
            Application.Storage.setValue("poolLengthIdx", poolLengthIdx);
        }
    }

    function decreasePoolLength() as Void {
        if (poolLengthIdx > 0) {
            poolLengthIdx--;
            Application.Storage.setValue("poolLengthIdx", poolLengthIdx);
        }
    }

    function resetActivity() as Void {
        state                 = STATE_READY;
        lapCount              = 0;
        totalDistanceM        = 0;
        elapsedMs             = 0;
        currentPaceSecPer100m = 0;
        _startTime            = null;
        _pauseStartTime       = null;
        _totalPausedMs        = 0;
        _lastLapStartMs       = 0;
        _lapTimes             = [] as Array<Number>;
        isRecording           = false;
        _distanceField        = null;
        _lapDistanceField     = null;
        strokeCountPeaks      = 0;
        strokeCountEstimate   = 0;
        _lastStrokeEstimateMs = 0;
        _fastAccel            = 0.0f;
        _baselineAccel        = 0.0f;
        _isSwimming           = false;
        _swimStartMs          = 0;
        _peakDetected         = false;
        _lastPeakMs           = 0;
        debugAmpX             = 0.0f;
        debugAmpY             = 0.0f;
        debugAmpZ             = 0.0f;
        debugAmpMax           = 0.0f;
        debugFastAccel        = 0.0f;
        debugBaseline         = 0.0f;
        debugRatio            = 0.0f;
        debugMaxAmpEver       = 0.0f;
        debugMinAmpEver       = 999.0f;
    }
}