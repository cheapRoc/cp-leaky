import csv
import glob

heap_files = glob.glob('profile/heap-*')
csvfile = 'output.csv'
csv_rows = []

csv_fields = [
    'timestamp',
    'Alloc',
    'TotalAlloc',
    'Sys',
    'Lookups',
    'Mallocs',
    'Frees',
    'HeapAlloc',
    'HeapSys',
    'HeapIdle',
    'HeapInuse',
    'HeapReleased',
    'HeapObjects',
    'Stack.top',
    'Stack.bottom',
    'MSpan.top',
    'MSpan.bottom',
    'MCache.top',
    'MCache.bottom',
    'BuckHashSys',
    'GCSys',
    'OtherSys',
    'NextGC',
]

def process_line(row, line):

    def split_top_bottom(line):
        val = line.split('=')[1].split('/')
        top = val[0].strip()
        bottom = val[1].strip()
        return top, bottom

    if line.startswith('# Stack ='):
        top, bottom = split_top_bottom(line)
        row['Stack.top'] = top
        row['Stack.bottom'] = top
        return
    elif line.startswith('# MSpan ='):
        top, bottom = split_top_bottom(line)
        row['MSpan.top'] = top
        row['MSpan.bottom'] = top
        return
    elif line.startswith('# MCache ='):
        top, bottom = split_top_bottom(line)
        row['MCache.top'] = top
        row['MCache.bottom'] = top
        return

    for field in csv_fields:
        if line.startswith('# {} ='.format(field)):
            row[field] = line.split('=')[1].strip()


output_file = open(csvfile, 'w')
writer = csv.DictWriter(output_file, fieldnames=csv_fields)
writer.writeheader()

for heap_file in heap_files:
    with open(heap_file, 'r') as f:
        print('processing {}...'.format(heap_file))
        row = {'timestamp': heap_file.split('-')[1]}
        start_processing = False
        for line in f.readlines():
            if start_processing:
                process_line(row, line)
            else:
                if line.startswith('# runtime.MemStats'):
                    start_processing = True
        print(row)
        writer.writerow(row)

output_file.close()
