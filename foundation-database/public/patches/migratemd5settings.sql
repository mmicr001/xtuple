SELECT setMetric('CCANCheckSigKey', fetchMetricText('CCANMD5HashSetOnGateway')),
       setMetric('CCANSigKeyAction', fetchMetricText('CCANMD5HashAction'));

DELETE FROM metric
 WHERE metric_name IN ('CCANMD5Hash', 'CCANMD5HashSetOnGateway', 'CCANMD5HashAction');
