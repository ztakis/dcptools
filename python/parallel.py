from multiprocessing import Process

def numbers(start_num):
    for i in range(5):
        print(start_num+i, end=' ')

if __name__ == '__main__':
    p1 = Process(target=numbers, args=(1,))
    p2 = Process(target=numbers, args=(10,))
    p1.start()
    p2.start()
    # wait for the processes to finish
    p1.join()
    p2.join()